#!/bin/bash -lex

### This is the launch script for Graphistry.
### There are many important shell parameters that govern behavior.
###
### $GRAPHISTRY_NETWORK is the name of the network it runs in. Override this with "staging", or "production", or "demo2".
### $DB_BACKUP_DIRECTORY is where Postgres backups end up. We are not yet doing backups; this is DEV-879.
### $PG_USER and $PG_PASS configure the database user that the app uses.
### $GRAPHISTRY_APP_CONFIG is the json override for app configuration, like '{"LOG_LEVEL": "DEBUG"}', that gets filtered through supervisord.
### $GRAPHISTRY_DATA_CACHE is where datasets get written to disk.
### $GRAPHISTRY_WORKBOOK_CACHE is where workbooks get written to disk.
### $GRAPHISTRY_PIVOT_CACHE is where pivots and investigations get written to disk.
### $NGINX_HTTP_PORT and $NGINX_HTTPS_PORT are where we expose our app to the host.


if [ -n "${SHIPYARD}" ]
then
    VIZ_APP_BASE_CONTAINER="<VIZAPP_CONTAINER_NAME>"
    NGINX_BASE_CONTAINER="us.gcr.io/psychic-expanse-187412/graphistry/release/nginx-central-vizservers:925"
    PIVOT_APP_BASE_CONTAINER="<PIVOTAPP_CONTAINER_NAME>"
else
    VIZ_APP_BASE_CONTAINER="graphistry/viz-app:$1"
    NGINX_BASE_CONTAINER="graphistry/nginx-central-vizservers:1.4.0.32"
    PIVOT_APP_BASE_CONTAINER="graphistry/pivot-app:$2"
fi


### 0. Ensure that we can get an OpenCL context.

if [ "${NV_GPU}" == "-1" ]
then
    RUNTIME=docker
else
    RUNTIME=nvidia-docker
fi

$RUNTIME run --rm ${VIZ_APP_BASE_CONTAINER} clinfo

### 1. Ensure we have a network for our application to run in.

GRAPHISTRY_NETWORK=${GRAPHISTRY_NETWORK:-monolith-network}
docker network inspect $GRAPHISTRY_NETWORK || docker network create $GRAPHISTRY_NETWORK

### 2. Postgres.

DB_BACKUP_DIRECTORY=${DB_BACKUP_DIRECTORY:-$PWD/../.pgbackup-$GRAPHISTRY_NETWORK}
PG_USER=${PG_USER:-graphistry}
PG_PASS=${PG_PASS:-graphtheplanet}
PG_BOX_NAME=${GRAPHISTRY_NETWORK}-pg
PG_PORT=5432

if (docker exec $PG_BOX_NAME psql -c "select 'database is up' as healthcheck" postgresql://${PG_USER}:${PG_PASS}@${PG_BOX_NAME}:${PG_PORT}) ; then
  echo Keeping db.
else
  echo Bringing up db.
  docker run -d --restart=unless-stopped --net none --name ${PG_BOX_NAME} -e POSTGRES_USER=${PG_USER} -e POSTGRES_PASSWORD=${PG_PASS} postgres:9-alpine
  if [ -z $DB_RESTORE ] ; then
    echo Nothing to restore.
  else
    echo Restoring db with the contents of ${DB_RESTORE}.
    for i in {1..100} ; do
        if [[ $(docker exec $PG_BOX_NAME psql -U${PG_USER} -c "select 'database is up' as healthcheck") ]]; then
            break
        else
            sleep 5
        fi
    done
    gzip -cd ${DB_RESTORE} | docker exec -i $PG_BOX_NAME psql -U${PG_USER}
  fi
  docker network disconnect none $PG_BOX_NAME
  docker network connect $GRAPHISTRY_NETWORK $PG_BOX_NAME
fi
BACKUP_SLEEP=86400
MAX_DB_BACKUPS=10
DB_BU_BUCKET=$DB_BU_BUCKET
DB_BU_ACCESS=$DB_BU_ACCESS
DB_BU_SECRET=$DB_BU_SECRET
DB_BU_BOX_NAME=${GRAPHISTRY_NETWORK}-db-bu
docker rm -f $DB_BU_BOX_NAME || true
docker run -d --name $DB_BU_BOX_NAME -e MAX_DB_BACKUPS=$MAX_DB_BACKUPS -e BACKUP_SLEEP=$BACKUP_SLEEP -e DB_BU_BUCKET=$DB_BU_BUCKET -e DB_BU_ACCESS=$DB_BU_ACCESS -e DB_BU_SECRET=$DB_BU_SECRET --network=$GRAPHISTRY_NETWORK -e PGUSER=${PG_USER} -e PGPASSWORD=${PG_PASS} -e PGHOST=${PG_BOX_NAME} --restart=unless-stopped -v $DB_BACKUP_DIRECTORY:/backup -w /backup graphistry/s3cmd-postgres sh -c '(pg_dump | gzip -c > $(date +%s).sql.gz) && (ls -t . | tail -n +$(( MAX_DB_BACKUPS + 1)) | xargs --no-run-if-empty rm) && ( [ -z $DB_BU_BUCKET ] && echo No bucket, keeping db bu local || s3cmd --access_key=$DB_BU_ACCESS --secret_key=$DB_BU_SECRET sync /backup/ s3://$DB_BU_BUCKET ) && sleep $BACKUP_SLEEP'

### 3. Cluster membership.

MONGO_BOX_NAME=${GRAPHISTRY_NETWORK}-mongo

docker rm -f -v $MONGO_BOX_NAME || true
docker run --net $GRAPHISTRY_NETWORK --restart=unless-stopped --name $MONGO_BOX_NAME -d mongo:2

for i in {1..50} ; do echo $i; docker exec $MONGO_BOX_NAME mongo --eval "2+2" || sleep $i; done
MONGO_NAME=cluster
MONGO_USERNAME=graphistry
MONGO_PASSWORD=graphtheplanet
docker exec $MONGO_BOX_NAME bash -c "mongo --eval '2+2' -u $MONGO_USERNAME -p $MONGO_PASSWORD localhost/$MONGO_NAME || (mongo --eval \"db.createUser({user: '$MONGO_USERNAME', pwd: '$MONGO_PASSWORD', roles: ['readWrite']})\" localhost/$MONGO_NAME && mongo --eval 'db.gpu_monitor.createIndex({updated: 1}, {expireAfterSeconds: 30})'  -u $MONGO_USERNAME -p $MONGO_PASSWORD localhost/$MONGO_NAME && mongo --eval 'db.node_monitor.createIndex({updated: 1}, {expireAfterSeconds: 30})' -u $MONGO_USERNAME -p $MONGO_PASSWORD localhost/$MONGO_NAME )"

### 4. API Gateway container
API_BOX_NAME=${GRAPHISTRY_NETWORK}-api-gateway
docker rm -f -v $API_BOX_NAME || true

### 5. Stop app, make log directories, start app.

VIZAPP_BOX_NAME=${GRAPHISTRY_NETWORK}-viz

docker rm -f -v $VIZAPP_BOX_NAME || true

mkdir -p central-app worker graphistry-json clients reaper

stat ../httpd-config.json || (echo '{}' > ../httpd-config.json)
echo "${GRAPHISTRY_APP_CONFIG:-"{}"}" > ./httpd-config.json

echo "${VIZ_APP_CONFIG:-"{}"}" > ./viz-app-config.json
# A prior bug caused the 'box override' config to be created as a directory instead of a file. This
# line checks if it's a directory and, if so, deletes it.
[[ -d ../viz-app-config.json ]] && rm -rf ../viz-app-config.json
stat ../viz-app-config.json || (echo '{}' > ../viz-app-config.json)

NPROC=${NPROC:-$(((which nproc > /dev/null) && nproc) || echo 1)}
CENTRAL_MERGED_CONFIG=$(docker   run --rm -v ${PWD}/../httpd-config.json:/tmp/box-config.json -v ${PWD}/httpd-config.json:/tmp/local-config.json ${VIZ_APP_BASE_CONTAINER} bash -c 'mergeThreeFiles.js $graphistry_install_path/central-cloud-options.json    /tmp/box-config.json /tmp/local-config.json')
VIZWORKER_MERGED_CONFIG=$(docker run --rm -e NPROC=$NPROC -v ${PWD}/../httpd-config.json:/tmp/box-config.json -v ${PWD}/httpd-config.json:/tmp/local-config.json ${VIZ_APP_BASE_CONTAINER} bash -c '(envsubst < $graphistry_install_path/viz-worker-cloud-options.json.envsubst > /tmp/default-config.json) && mergeThreeFiles.js /tmp/default-config.json /tmp/box-config.json /tmp/local-config.json')

$RUNTIME run \
    --net $GRAPHISTRY_NETWORK \
    --restart=unless-stopped \
    --name $VIZAPP_BOX_NAME \
    --link=${PG_BOX_NAME}:pg \
    --link=${MONGO_BOX_NAME}:mongo \
    -e "GRAPHISTRY_CENTRAL_CONFIG=${CENTRAL_MERGED_CONFIG}" \
    -e "GRAPHISTRY_VIZWORKER_CONFIG=${VIZWORKER_MERGED_CONFIG}" \
    -d \
    -v $PWD/../viz-app-config.json:/viz-app/config/z-box-override.json:ro \
    -v $PWD/viz-app-config.json:/viz-app/config/zzz-deploy-override.json:ro \
    -e "CONFIG_FILES=/viz-app/config/z-box-override.json,/viz-app/config/zzz-deploy-override.json" \
    -v ${PWD}/central-app:/var/log/central-app \
    -v ${PWD}/worker:/var/log/worker \
    -v ${PWD}/graphistry-json:/var/log/graphistry-json \
    -v ${PWD}/clients:/var/log/clients \
    -v ${PWD}/reaper:/var/log/reaper \
    -v ${GRAPHISTRY_DATA_CACHE:-${PWD}/data_cache}:/tmp/graphistry/data_cache \
    -v ${GRAPHISTRY_WORKBOOK_CACHE:-${PWD}/workbook_cache}:/tmp/graphistry/workbook_cache \
    -v ${PWD}/supervisor:/var/log/supervisor \
    ${VIZ_APP_BASE_CONTAINER}

### 5a. Start pivot-app.

PIVOTAPP_BOX_NAME=${GRAPHISTRY_NETWORK}-pivot

docker rm -f -v $PIVOTAPP_BOX_NAME || true

mkdir -p pivot-app
echo "${PIVOT_APP_CONFIG:-{}}" > ./pivot-config.json
[[ -d ../pivot-config.json ]] && rm -rf ../pivot-config.json
stat ../pivot-config.json || (echo '{}' > ../pivot-config.json)
PIVOT_LOG_LEVEL=${PIVOT_LOG_LEVEL:-debug}
docker run -d \
    --name $PIVOTAPP_BOX_NAME \
    --link=${PG_BOX_NAME}:pg \
    -e "NODE_ENV=production" \
    -e "GRAPHISTRY_LOG_LEVEL=$PIVOT_LOG_LEVEL" \
    -e "LOG_FILE=logs/pivot.log" \
    -v $PWD/pivot-app/:/pivot-app/logs \
    -v ${GRAPHISTRY_PIVOT_CACHE:-$PWD/../.pivot-db}:/pivot-app/data \
    -v $PWD/../pivot-config.json:/pivot-app/config/z-box-override.json:ro \
    -v $PWD/pivot-config.json:/pivot-app/config/zzz-deploy-override.json:ro \
    --link $VIZAPP_BOX_NAME:viz \
    --restart=unless-stopped \
    --network=$GRAPHISTRY_NETWORK \
    ${PIVOT_APP_BASE_CONTAINER}

### 6. Prometheus
PROMETHEUS_BOX_NAME=${GRAPHISTRY_NETWORK}-prometheus
docker rm -f -v $PROMETHEUS_BOX_NAME || true

### 7. Zipkin
ZIPKIN_BOX_NAME=${GRAPHISTRY_NETWORK}-zipkin
docker rm -f -v $ZIPKIN_BOX_NAME || true

### 8. Nginx, maybe with ssl.

NGINX_BOX_NAME=${GRAPHISTRY_NETWORK}-nginx
NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-80}
NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT:-443}

docker rm -f -v $NGINX_BOX_NAME || true

if [ -n "$SSLPATH" ] ; then
    SSL_MOUNT="-v ${SSLPATH}:/etc/graphistry/ssl:ro"
    if [ -n "$SSL_SELF_PROVIDED" ] ; then
        SSL_CONFIG="-e SSL_CONFIG=/etc/nginx/graphistry/ssl-self-provided.conf"
    fi
    NGINX_IMAGE_SUFFIX=""
else
    SSL_MOUNT=""
    NGINX_IMAGE_SUFFIX=".httponly"
fi

docker run \
    --net $GRAPHISTRY_NETWORK \
    --restart=unless-stopped \
    --name $NGINX_BOX_NAME \
    -d \
    -p $NGINX_HTTP_PORT:80 \
    -p $NGINX_HTTPS_PORT:443 \
    --link=${VIZAPP_BOX_NAME}:vizapp \
    --link=${PIVOTAPP_BOX_NAME}:pivotapp \
    -v ${PWD}/nginx:/var/log/nginx $SSL_MOUNT $SSL_CONFIG \
    ${NGINX_BASE_CONTAINER}${NGINX_IMAGE_SUFFIX}


### 9. Splunk.

SPLUNK_BOX_NAME=${GRAPHISTRY_NETWORK}-splunk

docker rm -f -v $SPLUNK_BOX_NAME || true

if [ -n "$SPLUNK_PASSWORD" ] ; then
    docker run --name $SPLUNK_BOX_NAME --restart=unless-stopped -d -v /etc/graphistry/splunk/:/opt/splunkforwarder/etc/system/local -v ${PWD}/central-app:/var/log/central-app -v ${PWD}/worker:/var/log/worker -v ${PWD}/graphistry-json:/var/log/graphistry-json -v ${PWD}/clients:/var/log/clients -v ${PWD}/reaper:/var/log/reaper -v ${PWD}/supervisor:/var/log/supervisor -v ${PWD}/nginx:/var/log/nginx -v ${PWD}/pivot-app:/var/log/pivot-app graphistry/splunkfwd:6.4.1 bash -c "/opt/splunkforwarder/bin/splunk edit user admin -password $SPLUNK_PASSWORD -auth admin:$SPLUNK_ADMIN --accept-license --answer-yes ; /opt/splunkforwarder/bin/splunk start --nodaemon --accept-license --answer-yes"
fi

### Done.

### Run-time database load.

docker exec $VIZAPP_BOX_NAME bash -c 'for f in /var/graphistry/packages/central/assets/datasets/[A-Za-z0-9_]* ; do mv $f /tmp/graphistry/data_cache/$(basename $f).$(basename $f | tr -dc A-Za-z | shasum | cut -d " " -f 1) ; done'

echo SUCCESS.
echo Graphistry has been launched, and should be up and running.
echo SUCCESS.

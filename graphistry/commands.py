from fabric.api import task, run, settings, env, local, hide
from requests.auth import HTTPBasicAuth
import requests
import os, errno, sys
import json
from jinja2 import Environment
import getpass
import base64
import codecs
from pprint import pprint

DEBUG = False
SHIPYARD_HOST = 'https://shipyard.graphistry.com'
if DEBUG:
    SHIPYARD_HOST = 'http://localhost:8000'

__Commands__ = ['stop', 'update', 'config', 'launch']

@task
def stop():
    """
    Stop all running containers
    :return:
    """
    local('docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)')


def create_config_files(filename, text):
    try:
        _file = open(filename, "w")
        _file.write(text)
        _file.close()
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise


def configure(grph_conf):
    jenv = Environment()
    jenv.filters['jsonify'] = json.dumps

    for key, value in grph_conf['file_conf'].items():
        create_config_files(value['filename'],
                            jenv.from_string(value['template']).render(value['context']))

    with open('.graphistry.json', 'w') as outfile:
        json.dump(grph_conf, outfile, ensure_ascii=False, indent=4, sort_keys=True)

    return grph_conf


def get_context(name):
    if name == 'pivot':
        print('All uris without scheme please. www.example.com not https://www.examples./com')
        tls = input('Use SSL? [y/n default n]: ')
        if tls == 'y':
            scheme = 'https://'
        else:
            scheme = 'http://'
        grph_uri = input("Your FQDN for this deployment [e.g., graphistry.yourcompany.com]: ")
        grph_uri = scheme+grph_uri

        password = getpass.getpass("Basic auth ingress password: ")
        with hide('output','running','warnings'), settings(warn_only=True):
            password_hash = local('bcrypt-cli "{0}" 10'.format(password), capture=True)

        return {"data_dir": 'test/appdata',
                "graphistry_host": grph_uri,
                "es_host": input("Your hostname of Elasticsearch server: "),
                "password_hash": password_hash.stdout}
    if name == 'httpd':
        return {"s3_access": input("Your AWS_ACCESS_KEY_ID: "),
                "s3_secret": input("Your AWS_SECRET_ACCESS_KEY: ")}
    if name == 'viz':
        return {}

@task
def load_containers(from_login=False):
    """
    Load containers from containers.tar
    """
    if os.path.exists('containers.tar'):
        print("Archived containers detected (containters.tar) would you like to load containers from archive?")
        load_containers = input("[y/n]: ")
        if load_containers == 'y' or load_containers == 'yes':
            local('docker load -i containers.tar')
    else:
        print('No containers.tar found')


def login():
    print("\nlogin to Graphistry Shipyard")
    username = input("username: ")
    password = getpass.getpass("password: ")
    res = requests.get('{0}/api/v1/config/?format=json'.format(SHIPYARD_HOST),
                       auth=HTTPBasicAuth(username, password))

    if res.status_code == 401:
        print('Invalid Username/Password')
        sys.exit()
    elif res.status_code == 403:
        print('You do not have permissions to do this action. Ask your administrator to upgrade your account.')
        sys.exit()

    conf = res.json()
    conf = conf['results'][0]['default_deployment']
    print('vizapp container: {0}\npivotapp container: {1}'.format(conf['vizapp_container'], conf['pivotapp_container']))
    local("cat launch.sh.tmpl | sed -e 's!<VIZAPP_CONTAINER_NAME>!{vizapp_container_name}!g' | sed -e 's!<PIVOTAPP_CONTAINER_NAME>!{pivotapp_container_name}!g' > deploy/launch.sh".format(
        vizapp_container_name=conf['vizapp_container'],
        pivotapp_container_name=conf['pivotapp_container']))

    files = {
        'pivot': {  'filename': 'pivot-config.json',
                    'template': conf['bundle']['pivot_config'],
                    'context': get_context('pivot')},
        'httpd': {  'filename': 'httpd-config.json',
                    'template': conf['bundle']['httpd_config'],
                    'context': get_context('httpd')},
        'viz': {    'filename': 'viz-app-config.json',
                    'template': conf['bundle']['viz_config'],
                    'context': get_context('viz')},
    }

    extra_conf = {
        'containers': {
            'vizapp': conf['vizapp_container'],
            'pivotapp': conf['pivotapp_container']
        }
    }

    with open('.registrykey.json', 'w') as outfile:
        json.dump(conf['registry_credentials'], outfile, ensure_ascii=False, indent=4, sort_keys=True)

    load_containers(from_login=True)

    return {'file_conf': files, 'extra_conf': extra_conf}



@task
def config():
    """
    This gets your deployment configuration for bootstrapping graphistry

    :param username: Your Graphistry Deploy Username
    :param password: Your Graphistry Deploy Password
    :param deployment: Deployment ID
    :return:
    """
    if os.path.exists('.graphistry.json'):
        ow_conf = input('Do you want to overwrite your config? [y/n default n]: ')
        if ow_conf != 'y':
            with open('.graphistry.json', 'r') as conf_file:
                grph_config = json.loads(conf_file.read())
                configure(grph_config)
        else:
            configure(login())
    else:
        configure(login())

    local('docker login -u _json_key -p "$(cat .registrykey.json)" https://us.gcr.io')


@task
def launch(ssl=False, ssl_path='/etc/graphistry/ssl'):
    """
    Launch your graphistry stack
    :return:
    """
    local('cd deploy && chmod +x launch.sh')
    if ssl:
        local('export SSLPATH="{ssl_path}" && cd deploy && bash launch.sh'.format(ssl_path=ssl_path))
    else:
        local('cd deploy && bash launch.sh')

@task
def clean(delete_images=False):
    if os.path.exists('pivot-config.json'):
        local('rm pivot-config.json')
    if os.path.exists('httpd-config.json'):
        local('rm httpd-config.json')
    if os.path.exists('viz-app-config.json'):
        local('rm viz-app-config.json')
    if os.path.exists('fabfile.pyc'):
        local('rm fabfile.pyc')
    stop()
    if delete_images:
        local('docker rmi $(docker images -q)')
    local('mv deploy/launch.sh /tmp/launch.sh')
    local('sudo rm -rf deploy && mkdir deploy')
    local('mv /tmp/launch.sh deploy/launch.sh')


@task
def update():
    print("\nlogin to Graphistry Shipyard")
    username = input("username: ")
    password = getpass.getpass("password: ")
    res = requests.get('{0}/api/v1/config/?format=json'.format(SHIPYARD_HOST),
                       auth=HTTPBasicAuth(username, password))

    if res.status_code == 401:
        print('Invalid Username/Password')
        sys.exit()
    elif res.status_code == 403:
        print('You do not have permissions to do this action. Ask your administrator to upgrade your account.')
        sys.exit()

    conf = res.json()

    local('cp fabfile.py fabfile.py.bak')
    try:
        with open('fabfile.py', 'wb') as outfile:
            outfile.write(base64.b64decode(conf['results'][0]['default_deployment']['service_script']))
        if not os.path.exists('deploy'):
            local('mkdir deploy')
        with open('launch.sh.tmpl', 'wb') as outfile:
            outfile.write(base64.b64decode(conf['results'][0]['default_deployment']['bundle']['launch_script']))
            with hide('output', 'running', 'warnings'), settings(warn_only=True):
                local("sed -i 's!\r!!g' launch.sh.tmpl")
    except KeyError:
        print('You appear to not have a configuration profile set up. Contact your administrator')
        local('cp fabfile.py.bak fabfile.py')

@task
def load():
    """
    This will load the pivotdb test data.
    :return:
    """

    print("\nlogin to Graphistry Shipyard")
    username = input("username: ")
    password = getpass.getpass("password: ")
    res = requests.get('{0}/api/v1/config/?format=json'.format(SHIPYARD_HOST),
                       auth=HTTPBasicAuth(username, password))

    if res.status_code == 401:
        print('Invalid Username/Password')
        sys.exit()
    elif res.status_code == 403:
        print('You do not have permissions to do this action. Ask your administrator to upgrade your account.')
        sys.exit()

    conf = res.json()
    if not os.path.exists('.pivot-db'):
        local('mkdir -p .pivot-db')
    if not os.path.exists('.pivot-db/investigations'):
        local('mkdir -p .pivot-db/investigations')
    if not os.path.exists('.pivot-db/pivots'):
        local('mkdir -p .pivot-db/pivots')

    with hide('output', 'running', 'warnings'), settings(warn_only=True):
        local('sudo chmod -R 777 .pivot-db')
    for inv in conf['results'][0]['default_deployment']['investigations']:
        try:
            print("writing investigation {0}".format(inv['name']))
            with open('.pivot-db/investigations/{id}.json'.format(id=inv['json']['id']), 'w') as outfile:
                json.dump(inv['json'], outfile, ensure_ascii=False, indent=4, sort_keys=True)

            for piv in inv['pivots']:
                print("writing pivot {0}".format(piv['name']))
                with open('.pivot-db/pivots/{id}.json'.format(id=piv['json']['id']), 'w') as outfile:
                    json.dump(piv['json'], outfile, ensure_ascii=False, indent=4, sort_keys=True)
        except Exception as e:
            print(e)
    with hide('output', 'running', 'warnings'), settings(warn_only=True):
        local('sudo chmod -R 777 .pivot-db')


@task
def read_logs(show_result=False, app='pivot'):
    """
    do graphistry read_logs:show_result=True to see the query results from elasticsearch
    """

    if app == 'pivot':
        file_path = 'deploy/pivot-app/pivot.log'
        data = []
        with codecs.open(file_path, 'rU', 'utf-8') as logfile:
            for line in logfile:
                entry = json.loads(line)
                if 'msg' in entry:
                    if 'Elasticsearch connect' in entry['msg']:
                        if 'query' in entry:
                            entry['query'] = json.loads(entry['query'])
                        print(entry['msg'])
                        data.append(entry)
        for xx in data:
            if 'result' in xx and not show_result:
                continue

            print("\n\n######################################\n## {0}\n#########\n\n".format(xx['msg']))
            print("\n\n### Query ###\n")
            pprint(xx['query'])
            if 'result' in xx and show_result:
                print("\n\n### Result ###\n")
                pprint(xx['result'])
            if 'err' in xx:
                print("\n\n### Error ###\n")
                pprint(xx['err'])


@task
def pull(containers=None):
    if not containers:
        with open('.graphistry.json', 'r') as conf_file:
            settings = json.loads(conf_file.read())
            containers = settings['extra_conf']['containers']
    local('docker pull openzipkin/zipkin:2')
    local('docker pull graphistry/s3cmd-postgres:latest')
    local('docker pull graphistry/prometheus:latest')
    local('docker pull postgres:9-alpine')
    local('docker pull us.gcr.io/psychic-expanse-187412/graphistry/api-gateway:latest')
    local('docker pull us.gcr.io/psychic-expanse-187412/graphistry/nginx-central-vizservers:1.4.0.32.httponly')
    local('docker pull mongo:2')
    local('docker pull {0}'.format(containers['vizapp']))
    local('docker pull {0}'.format(containers['pivotapp']))


@task
def compile():
    if not os.path.exists('.graphistry.json'):
        config()
    with open('.graphistry.json', 'r') as conf_file:
        settings = json.loads(conf_file.read())
        containers = settings['extra_conf']['containers']

        try:
            local('docker save -o containers.tar '
                  'openzipkin/zipkin:2 '
                  'graphistry/s3cmd-postgres:latest '
                  'graphistry/prometheus:latest '
                  'postgres:9-alpine '
                  'us.gcr.io/psychic-expanse-187412/graphistry/api-gateway:latest '
                  'us.gcr.io/psychic-expanse-187412/graphistry/nginx-central-vizservers:1.4.0.32.httponly '
                  'mongo:2 '
                  '{0} {1}'.format(containers['vizapp'], containers['pivotapp']))
            local('echo -e "#\!/bin/bash\ndocker load -i containers.tar" > load.sh && chmod +x load.sh')
            if not os.path.exists('dist'):
                local('mkdir dist')
            print('Compiling Distrobution Bundle [dist/graphistry.tar.gz]. This will take a a few minutes.')
            local('touch dist/graphistry.tar.gz && tar -czf dist/graphistry.tar.gz ./deploy/launch.sh httpd-config.json load.sh pivot-config.json viz-app-config.json containers.tar')
        except KeyError:
            print("Invalid '.graphistry.json'. Please run 'graphistry config' to repair")
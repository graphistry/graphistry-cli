# Some Additional Features for Developers and Sysadmins

## Sending a compiled Graphistry distrobution to s3 to install on other systems
```bash
sudo pip install awscli
aws configure
aws s3 cp dist/graphistry.tar.gz s3://<yourbucket>/graphistry.tar.gz
aws s3 presign s3://<yourbucket>/graphistry.tar.gz
```

## Download the bundle from s3 with `awscli`

```bash
aws s3 cp s3://<yourbucket>/graphistry.tar.gz graphistry.tar.gz
```

## Download the bundle from s3 with `wget`

```bash
wget -O graphistry.tar.gz  '<url returned from presign>' # quoting that string is important
```

If you want to get, extract, and bootstrap all in one command:
```bash
PRESIGN_URL="<url returned from presign>" # quoting that string is important
wget -O graphistry.tar.gz  "${PRESIGN_URL}" && tar -xvf graphistry.tar.gz && ./bootstrap.sh [rhel|ubuntu]
```

## Download the bundle from s3 with `curl`

**get_s3_object.sh**
```bash
#!/bin/sh
file=graphistry.tar.gz
bucket=your-bucket
resource="/${bucket}/${file}"
contentType="application/x-compressed-tar"
dateValue="`date +'%a, %d %b %Y %H:%M:%S %z'`"
stringToSign="GET
${contentType}
${dateValue}
${resource}"
s3Key=xxxxxxxxxxxxxxxxxxxx
s3Secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
signature=`/bin/echo -en "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64`
curl -H "Host: ${bucket}.s3.amazonaws.com" \
-H "Date: ${dateValue}" \
-H "Content-Type: ${contentType}" \
-H "Authorization: AWS ${s3Key}:${signature}" \
https://${bucket}.s3.amazonaws.com/${file}
```
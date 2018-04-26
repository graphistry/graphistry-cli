# Some Additional Features for Developers and Sysadmins

## Sending a compiled Graphistry distrobution to s3 to install on other systems
```
sudo pip install awscli
aws configure
aws s3 cp graphistry.tar.gz s3://airgapped-deploy/graphistry.tar.gz
aws s3 presign s3://airgapped-deploy/graphistry.tar.gz

wget -O graphistry.tar.gz  '<url returned from presign>' # quoting that string is important
```
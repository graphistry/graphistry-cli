import errno
import os
from os.path import expanduser, exists, dirname, realpath, join
from configmanager import Config
import requests
from prompt_toolkit import prompt
from graphistry.widgets import revisionist_commit_history_html
import sys, json
from requests.auth import HTTPBasicAuth
from fabric.api import local, settings, hide
import bcrypt
from jinja2 import Environment

cwd = dir_path = dirname(realpath(__file__))

DEBUG = False
SHIPYARD_HOST = 'https://shipyard.graphistry.com'
if DEBUG:
    SHIPYARD_HOST = 'http://localhost:8000'


def config_location():
    if 'GRAPHISTRY_CONFIG_HOME' in os.environ:
        return '%s/graphistry/' % expanduser(os.environ['GRAPHISTRY_CONFIG_HOME'])
    else:
        return expanduser('~/.config/graphistry/')


def ensure_dir_exists(path):
    parent_dir = expanduser(dirname(path))
    try:
        os.makedirs(parent_dir)
    except OSError as exc:
        # ignore existing destination (py2 has no exist_ok arg to makedirs)
        if exc.errno != errno.EEXIST:
            raise

def create_config_files(filename, text):
    try:
        _file = open(filename, "w")
        _file.write(text)
        _file.close()
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise

CONFIG_SCHEMA = {
    'user': {
        'name': '',
        'username': '',
    },
    'slug': '',
    'deployments': {},
    'default_deployment': {},
    'investigations': [],
    'registry_credentials': {},
    'vizapp_container': 'us.gcr.io/psychic-expanse-187412/graphistry/release/viz-app:925',
    'pivotapp_container': 'us.gcr.io/psychic-expanse-187412/graphistry/release/pivot-app:925',
    'is_airgapped': False,
    'use_ssl': False,
    'graphistry_host': '',
    'es_host': '',
    'es_port': '9200',
    'splunk_host': '',
    'splunk_port': '3000',
    'splunk_user': '',
    'splunk_password': '',
    'ip_internal_accept_list': '',
    'http_user': '',
    'http_password_hash': '',
    's3_access': '',
    's3_secret': '',
}

class Graphistry(object):
    config = None
    config_json = None

    def __init__(self):
        self.config_file = os.path.join(config_location(), 'config.json')

    def get_config(self, schema=None):
        if not schema:
            schema = CONFIG_SCHEMA
        self.config = Config(schema=schema)

        return self.config

    def create_bcrypt_container(self):
        make_bcrypt = join(cwd, 'bootstrap/make-bcrypt-contianer.sh')
        local('sudo bash {mb}'.format(mb=make_bcrypt))


    def login(self):
        toolbar_quip = revisionist_commit_history_html()
        username = prompt('username: ', bottom_toolbar=toolbar_quip, history=None)
        password = prompt('password: ', bottom_toolbar=toolbar_quip, history=None, is_password=True)
        res = requests.get('{0}/api/v1/config/?format=json'.format(SHIPYARD_HOST),
                           auth=HTTPBasicAuth(username, password))

        if res.status_code == 401:
            print('Invalid Username/Password')
            sys.exit()
        elif res.status_code == 403:
            print('You do not have permissions to do this action. Ask your administrator to upgrade your account.')
            sys.exit()

        conf = res.json()['results'][0]
        schema = {
            'user': conf['user'],
            'default_deployment': conf['default_deployment'],
            'investigations': [],
            'registry_credentials': conf['default_deployment']['registry_credentials'],
            'vizapp_container': conf['vizapp_container'],
            'pivotapp_container': conf['pivotapp_container'],
            'is_airgapped': False,
            'use_ssl': False,
            'graphistry_host': '',
            'es_host': '',
            'es_port': '9200',
            'splunk_host': '',
            'splunk_port': '3000',
            'splunk_user': '',
            'splunk_password': '',
            'ip_internal_accept_list': '',
            'http_user': '',
            'http_password_hash': '',
            's3_access': '',
            's3_secret': '',


        }
        self.get_config(schema)

    def load_config(self):
        print("Loading Config")
        if exists(self.config_file):
            self.config = Config(
                schema=CONFIG_SCHEMA,
                load_sources=[self.config_file],
                auto_load=True,
            )
            self.config.json.load(self.config_file)
        else:
            self.login()
        return self.config

    def template_config(self):
        toolbar_quip = revisionist_commit_history_html()
        self.load_config()

        # Graphistry Basic
        self.config.is_airgapped.value = True if exists(expanduser('~/.graphistry_airgapped')) else False
        self.config.use_ssl.value = prompt('Use SSL? [y/n default n]: ',
                                           bottom_toolbar=toolbar_quip, history=None)

        self.config.graphistry_host.value = prompt('Your FQDN for this deployment [e.g., graphistry.yourcompany.com]: ',
                                                   bottom_toolbar=toolbar_quip, history=None)

        # Elasticsearch
        self.config.es_host.value = prompt('Your Elasticsearch Host: ',
                                           bottom_toolbar=toolbar_quip, history=None)
        self.config.es_port.value = prompt('Your Elasticsearch Port [default: 9200]: ',
                                           bottom_toolbar=toolbar_quip, history=None)

        # Splunk
        self.config.splunk_host.value = prompt('Your Splunk Host: ',
                                               bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_port.value = prompt('Your Splunk Port [default: 3000]: ',
                                               bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_user.value = prompt('Your Splunk Username: ',
                                               bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_password.value = prompt('Your Splunk Password: ',
                                                   bottom_toolbar=toolbar_quip, history=None, is_password=True)

        # Ip Whitelist
        self.config.ip_internal_accept_list.value = prompt('Your Interal Ip Accept Whitelist '
                                                           '[comma seperated please]: ',
                                                           bottom_toolbar=toolbar_quip, history=None, is_password=True)

        # Http Ingress
        self.config.http_user.value = prompt('Pivotapp Http Ingress Username: ',
                                             bottom_toolbar=toolbar_quip, history=None)
        password = prompt('Pivotapp Http Ingress Password: ',
                          bottom_toolbar=toolbar_quip,
                          history=None,
                          is_password=True)
        with hide('output', 'running', 'warnings'), settings(warn_only=True):
            self.config.http_password_hash.value = local('docker run -it bcrypt bcrypt-cli "{0}" 10'.format(password),
                                                         capture=True)

        # AWS
        self.config.s3_access.value = prompt('AWS Access Key Id: ', bottom_toolbar=toolbar_quip, history=None)
        self.config.s3_secret.value = prompt('AWS Access Key Secret: ', bottom_toolbar=toolbar_quip, history=None)


        self.save_config()
        self.write_configs()

    def write_configs(self):
        jenv = Environment()
        jenv.filters['jsonify'] = json.dumps
        templates = ['pivot-config.json', 'httpd-config.json', 'viz-app-config.json']
        for tmpl in templates:
            _file = open(cwd+'/templates/'+tmpl, "r")
            create_config_files(tmpl, jenv.from_string(_file.read()).render(self.config.dump_values()))
            _file.close()

    def gcloud_auth(self):
        # Just snag whatever credentials are in the config and make sure the key is saved.
        # docker-py doesn't seem to want to accept the JSON string as a password so this works.
        key_filename = os.path.join(expanduser('~/.config/graphistry'), '.registrykey.json')
        registry_credentials = json.dumps(dict(self.config.default_deployment.value['registry_credentials']))
        _file = open(key_filename, "w")
        _file.write(registry_credentials)
        _file.close()

        local('docker login -u _json_key -p "$(cat {0})" https://us.gcr.io | tee'.format(key_filename))

    def save_config(self):
        print("Saving Config")
        location = config_location()

        ensure_dir_exists(location)

        if self.config:
            self.config.json.dump(self.config_file, with_defaults=True)


            """
            
            HOST1=ec2-user@ec2-54-202-44-174.us-west-2.compute.amazonaws.com
            HOST2=ec2-user@ec2-34-217-121-70.us-west-2.compute.amazonaws.com
            SRC=/home/ec2-user/dist/graphistry.tar.gz
            DST=/home/ec2-user/graphistry.tar.gz
            
SOURCE_USER=ec2-user
SOURCE_HOST=ec2-user@ec2-54-202-44-174.us-west-2.compute.amazonaws.com
SOURCE_PATH=/home/ec2-user/dist/graphistry.tar.gz

TARGET_USER=ec2-user
TARGET_HOST=ec2-user@ec2-34-217-121-70.us-west-2.compute.amazonaws.com
TARGET_PATH=/home/ec2-user/graphistry.tar.gz

ssh -l $TARGET_USER -A -R localhost:22000:$TARGET_HOST:22 \
$SOURCE_USER@$SOURCE_HOST "rsync -e 'ssh -p 22000' -vuar $SOURCE_PATH \
$TARGET_USER@localhost:$TARGET_PATH"
            
            ssh -R localhost:50000:$HOST1:22 $HOST2 'rsync -e "ssh $HOST2 -p 50000" -vuar $SRC localhost:$DST'

            ssh -R localhost:50000:ec2-user@ec2-34-217-121-70.us-west-2.compute.amazonaws.com:22 ec2-user@ec2-54-202-44-174.us-west-2.compute.amazonaws.com 'rsync -e "ssh -p 50000" -vuar /home/ec2-user/dist/graphistry.tar.gz localhost:/home/ec2-user/graphistry.tar.gz'
            
            """
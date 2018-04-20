import errno
import os
from os.path import expanduser, exists, dirname
from configmanager import Config
import requests
from prompt_toolkit import prompt
from widgets import revisionist_commit_history_html
import sys, json
from requests.auth import HTTPBasicAuth
from fabric.api import local

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
    'es_port': '',
    'splunk_host': '',
    'splunk_port': '',
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
        import pdb;
        pdb.set_trace()
        conf = res.json()['results'][0]
        schema = {
            'user': conf['user'],
            'default_deployment': conf['default_deployment'],
            'is_airgapped': False,
            'use_ssl': False,
            'graphistry_host': '',
            'es_host': '',
            'es_port': '',
            'splunk_host': '',
            'splunk_port': '',
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

        self.config.is_airgapped.value = True if exists(expanduser('~/.graphistry_airgapped')) else False
        self.config.use_ssl.value = prompt('Use SSL? [y/n default n]: ',
                                                   bottom_toolbar=toolbar_quip, history=None)

        self.config.graphistry_host.value = prompt('Your FQDN for this deployment [e.g., graphistry.yourcompany.com]: ',
                                                   bottom_toolbar=toolbar_quip, history=None)

        self.config.es_host.value = prompt('Your Elasticsearch Host: ',
                                                   bottom_toolbar=toolbar_quip, history=None)
        self.config.es_port.value = prompt('Your Elasticsearch Port [default: 9200]: ',
                                           bottom_toolbar=toolbar_quip, history=None)

        self.config.splunk_host.value = prompt('Your Splunk Host: ',
                                           bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_port.value = prompt('Your Splunk Port [default: 3000]: ',
                                           bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_user.value = prompt('Your Splunk Username: ',
                                           bottom_toolbar=toolbar_quip, history=None)
        self.config.splunk_password.value = prompt('Your Splunk Password: ',
                                           bottom_toolbar=toolbar_quip, history=None, is_password=True)

        self.config.ip_internal_accept_list.value = prompt('Your Interal Ip Accept Whitelist [comma seperated please]: ',
                                                   bottom_toolbar=toolbar_quip, history=None, is_password=True)

        self.config.http_user.value = prompt('Pivotapp Http Ingress Username: ',
                                               bottom_toolbar=toolbar_quip, history=None)
        self.config.http_password_hash.value = prompt('Pivotapp Http Ingress Password: ',
                                                   bottom_toolbar=toolbar_quip, history=None, is_password=True)

        self.config.s3_access.value = prompt('AWS Access Key Id: ', bottom_toolbar=toolbar_quip, history=None)
        self.config.s3_secret.value = prompt('AWS Access Key Secret: ', bottom_toolbar=toolbar_quip, history=None)


        self.save_config()

    def gcloud_auth(self):
        # Just snag whatever credentials are in the config and make sure the key is saved.
        # docker-py doesn't seem to want to accept the JSON string as a password so this works.
        key_filename = os.path.join(expanduser('~/.config/graphistry'), '.registrykey.json')
        if exists(key_filename):
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
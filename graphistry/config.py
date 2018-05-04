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
from jinja2 import Environment
import click
import string
import random

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


def id_generator(size=6, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))


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
    'vizapp_container': 'us.gcr.io/psychic-expanse-187412/graphistry/release/viz-app:942',
    'pivotapp_container': 'us.gcr.io/psychic-expanse-187412/graphistry/release/pivot-app:942',
    'is_airgapped': False,
    'api_canary': '',
    'api_secret': '',
    'graphistry_key': '',
    'graphistry_host': '',
    'es_host': '',
    'es_port': '9200',
    'es_protocol': 'http',
    'es_auth': '',
    'splunk_host': '',
    'splunk_web_port': '443',
    'splunk_api_port': '8089',
    'splunk_user': '',
    'splunk_password': '',
    'splunk_protocol': 'https',
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

    def load_investigations(self, airgapped=False):
        """
        This will load the pivotdb test data.
        :return:
        """
        self.load_config(airgapped)
        pivot_db = join(cwd, '.pivot-db')
        invest_dir = join(pivot_db, 'investigations')
        pivots_dir = join(pivot_db, 'pivots')
        
        print(pivot_db)
        if not os.path.exists(pivot_db):
            local('mkdir -p ' + pivot_db)

        if not os.path.exists(invest_dir):
            local('mkdir -p ' + invest_dir)

        if not os.path.exists(pivots_dir):
            local('mkdir -p ' + pivots_dir)

        with hide('output', 'running', 'warnings'), settings(warn_only=True):
            local('sudo chmod -R 777 ' + pivot_db)

        for inv in self.config.investigations.value:
            try:
                print("writing investigation {0}".format(inv['name']))
                investigation = join(invest_dir, '{id}.json'.format(id=inv['json']['id']))
                with open(investigation, 'w') as outfile:
                    json.dump(inv['json'], outfile, ensure_ascii=False, indent=4, sort_keys=True)

                for piv in inv['pivots']:
                    print("writing pivot {0}".format(piv['name']))
                    pivot = join(pivots_dir, '{id}.json'.format(id=piv['json']['id']), 'w')
                    with open(pivot) as outfile:
                        json.dump(piv['json'], outfile, ensure_ascii=False, indent=4, sort_keys=True)
            except Exception as e:
                print(e)

        with hide('output', 'running', 'warnings'), settings(warn_only=True):
            local('sudo chmod -R 777 ' + pivot_db)

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
            'investigations': conf['default_deployment']['investigations'],
            'registry_credentials': conf['default_deployment']['registry_credentials'],
            'vizapp_container': conf['default_deployment']['vizapp_container'],
            'pivotapp_container': conf['default_deployment']['pivotapp_container'],
            'is_airgapped': False,
            'api_canary': '',
            'api_secret': '',
            'graphistry_key': '',
            'graphistry_host': '',
            'es_host': '',
            'es_port': '9200',
            'es_protocol': 'http',
            'es_auth': '',
            'splunk_host': '',
            'splunk_web_port': '443',
            'splunk_api_port': '8089',
            'splunk_protocol': 'https',    
            'splunk_user': '',
            'splunk_password': '',
            'ip_internal_accept_list': '',
            'http_user': '',
            'http_password_hash': '',
            's3_access': '',
            's3_secret': '',


        }
        self.get_config(schema)

    def load_config(self, airgapped=False):
        print("Loading Config")
        if exists(self.config_file):
            self.config = Config(
                schema=CONFIG_SCHEMA,
                load_sources=[self.config_file],
                auto_load=True,
            )
            self.config.json.load(self.config_file)
        elif airgapped:
            self.get_config(CONFIG_SCHEMA)
        else:
            self.login()
        return self.config

    def template_config(self, airgapped=False):
        toolbar_quip = revisionist_commit_history_html()
        self.load_config(airgapped)

        self.config.is_airgapped.value = airgapped

        
        # Graphistry API Key Generation
        click.secho("[graphistry] Configure API key generation. [Hash algorithm is 'aes-256-cbc'.]", fg="yellow")
        
        api_canary = prompt('Hash Canary string (enter to autogenerate): ', bottom_toolbar=toolbar_quip, history=None)
        api_secret = prompt('Your Secret string (enter to autogenerate): ', bottom_toolbar=toolbar_quip, history=None)

        if api_canary == '':
            self.config.api_canary.value = id_generator(10)

        if api_secret == '':
            self.config.api_secret.value = id_generator(10)

        #self.config.graphistry_key.value = prompt('You supplied Graphisty key: ',
        #                                           bottom_toolbar=toolbar_quip, history=None)


        # Elasticsearch
        click.secho("[graphistry] Configure connectors", fg="yellow")
        self.config.es_host.value = prompt('Your Elasticsearch Host, e.g., elk.company.com (enter to skip): ',
                                           bottom_toolbar=toolbar_quip, history=None)
        if self.config.es_host.value != '':
            self.config.es_port.value = prompt('Your Elasticsearch Port [default: 9200]: ',
                                               bottom_toolbar=toolbar_quip, history=None)
            if self.config.es_port.value == '':
                self.config.es_port.value = CONFIG_SCHEMA['es_port']

            self.config.es_protocol.value = prompt('Your Elasticsearch Protocol [default: http]: ',
                                               bottom_toolbar=toolbar_quip, history=None)
            if self.config.es_protocol.value == '':
                self.config.es_protocol.value = CONFIG_SCHEMA['es_protocol']

            self.config.es_auth.value = prompt('Your Elasticsearch auth, e.g., user:password [default: none]: ',
                                               bottom_toolbar=toolbar_quip, history=None)
            if self.config.es_auth.value == '':
                self.config.es_auth.value = CONFIG_SCHEMA['es_auth']


        # Splunk
        self.config.splunk_host.value = prompt('Your Splunk Host, e.g., www.splunk.com (enter to skip): ',
                                               bottom_toolbar=toolbar_quip, history=None)
        if self.config.splunk_host.value != '':
            
            #### DEFAULTS
            self.config.splunk_api_port.value = prompt('Your Splunk API Port [default: 8089]: ',
                bottom_toolbar=toolbar_quip, history=None)
            if self.config.splunk_api_port.value == '':
                self.config.splunk_api_port.value = CONFIG_SCHEMA['splunk_api_port']

            self.config.splunk_web_port.value = prompt('Your Splunk Web UI Port [default: 443]: ',
                bottom_toolbar=toolbar_quip, history=None)
            if self.config.splunk_web_port.value == '':
                self.config.splunk_web_port.value = CONFIG_SCHEMA['splunk_web_port']

            self.config.splunk_protocol.value = prompt('Your Splunk Protocol, e.g., https [default: https]: ',
                bottom_toolbar=toolbar_quip, history=None)
            if self.config.splunk_protocol.value == '':
                self.config.splunk_protocol.value = CONFIG_SCHEMA['splunk_protocol']


            self.config.splunk_user.value = prompt('Your Splunk Username: ',
                                                   bottom_toolbar=toolbar_quip, history=None)
            self.config.splunk_password.value = prompt('Your Splunk Password: ',
                                                       bottom_toolbar=toolbar_quip, history=None, is_password=True)

        click.secho("[graphistry] Configure networking", fg="yellow")

        # Pivotapp->ETL/Vizapp
        self.config.graphistry_host.value = prompt('Your FQDN for this deployment, including protocol [e.g., http://graphistry.yourcompany.com]: ',
                                                   bottom_toolbar=toolbar_quip, history=None)

        # Ip Whitelist
        self.config.ip_internal_accept_list.value = prompt('Your Internal IP Accept Whitelist (beyond typical RFC 1918)'
                                                           ', ex:["127.0.0.1", "10.*"]',
                                                           bottom_toolbar=toolbar_quip, history=None)

        # Http Ingress
        self.config.http_user.value = prompt('HTTP Ingress Username: ',
                                             bottom_toolbar=toolbar_quip, history=None)
        password = prompt('HTTP Ingress Password: ',
                          bottom_toolbar=toolbar_quip,
                          history=None,
                          is_password=True)
        with hide('output', 'running', 'warnings'), settings(warn_only=True):
            self.config.http_password_hash.value = local('docker run -it bcrypt bcrypt-cli "{0}" 10'.format(password),
                                                         capture=True)

        # AWS
        self.config.s3_access.value = prompt('AWS Access Key ID (enter to skip): ', bottom_toolbar=toolbar_quip, history=None)
        if self.config.s3_access.value != '':
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

    def registry_auth(self):
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
            print("Wrote config:", self.config_file)




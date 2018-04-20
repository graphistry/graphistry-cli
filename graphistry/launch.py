from config import Graphistry
import json
import docker

class Cluster(object):
    def launch(self):
        _g = Graphistry()
        registry_credentials = json.dumps(dict(_g.config.default_deployment.value['registry_credentials']))
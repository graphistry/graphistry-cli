# Configure Investigations

Many Graphistry investigation configurations can be set through environment variables (your `data/config/custom.env`), in your `config/pivot-db/config/config.json`, or in the admin panel.

These control aspects including:

* Connector auth and defaults: Splunk, Neo4j, ...
* Layouts
* Ontology: See [main custom ontology docs](configure-ontology.md)
* Custom pivots: See [main custom pivot docs](configure-custom-pivots.md)
* Prepopulated investigation steps

After editing, restart your server, or at least `pivot`.

For broader configuration information, see the [main configuration docs](configure.md). Create [custom investigation templates](templates.md) directly from within the UI.

# Example

Set log level to debug:

Via `.env`:

```bash
GRAPHISTRY_LOG_LEVEL=DEBUG
```

Via `data/pivot-db/config/config.json`:
```json
{
  "log": {
    "level": "DEBUG"
  }
}
```

After setting these, restart your server:

* Full: `user@server.com : /var/graphistry $ docker-compose stop && docker-compose up -d`
* Pivot: `user@server.com : /var/graphistry $ docker-compose stop nginx pivot && docker-compose up -d`


# Schema

The schema specifies how to configure each setting as either an environment variable in `data/config/custom.env` (ex: `"env": "PIVOT_INTERNAL_IP_ACCEPTLIST"`) or as JSON in `data/pivot-db/config/config.json` following the schema's hierarchy + type `"format"` (ex: `{"layouts": {"network": { "ipInternalAcceptList": [ "ip1", "ip2"] } }}`)

See also: [main ontology docs](configure-ontology.md) and the [convict specification format](https://github.com/mozilla/node-convict/tree/master/packages/convict)

```json
{
  "env": {
    "doc": "The applicaton environment.",
    "format": [
      "production",
      "development",
      "test"
    ],
    "default": "development",
    "env": "NODE_ENV"
  },
  "host": {
    "doc": "Pivot host name/IP",
    "format": "ipaddress",
    "default": "0.0.0.0",
    "env": "PIVOT_HOST_IP"
  },
  "port": {
    "doc": "Pivot port number",
    "format": "port",
    "default": 8080,
    "arg": "port",
    "env": "PIVOT_PORT"
  },
  "layouts": {
    "network": {
      "ipInternalAcceptList": {
        "doc": "Array of strings and JavaScript regexes for IPs considered internal beyond those in RFC 1918",
        "arg": "internal-ips",
        "env": "PIVOT_INTERNAL_IP_ACCEPTLIST"
      }
    },
    "parallelCoordinates": {
      "orders": {
        "doc": "JSON dictionary naming axis column name orders. Defaults to key 'default' if available:\n                  {\n                    default:  [ 'dest_ip', 'src_ip' ],\n                    myOrder1: [ 'src_ip', 'dest_ip', 'time' ]\n                    ... \n                  }",
        "default": {},
        "arg": "parallel-coords-axes",
        "env": "GRAPHISTRY_PARALLEL_COORDS_AXES"
      }
    }
  },
  "authentication": {
    "passwordHash": {
      "doc": "Bcrypt hash of the password required to access this service, or unset/empty to disable authentication (default)",
      "default": "",
      "arg": "password-hash",
      "env": "PIVOT_PASSWORD_HASH",
      "sensitive": true
    },
    "username": {
      "doc": "The username used to access this service",
      "default": "admin",
      "arg": "username",
      "env": "PIVOT_USERNAME"
    }
  },
  "features": {
    "axes": {
      "default": true
    }
  },
  "systemTemplates": {
    "pivots": {
      "doc": "JSON list of pivots:\n                [{template, name, id, tags: [String],\n                    parameters: [{name, inputType, label, placeholder}]}],\n                    nodes: ?[String],\n                    attributes: ?[String],\n                    encodings: ?{size/icon/color:{<name>: <value>}}]",
      "default": [],
      "arg": "pivots",
      "env": "GRAPHISTRY_PIVOTS"
    }
  },
  "ontology": {
    "titles": {
      "byType": {
        "doc": "JSON dictionary from entity type to field name:\n                    { \"myType\": \"myField\", ... }",
        "default": {},
        "arg": "titles_by_type",
        "env": "GRAPHISTRY_TITLES_BY_TYPE"
      },
      "byField": {
        "doc": "Array of case-sensitive titles to use, highest-priority first. If no matches, use edgeTitle, pointTitle, else the ID.",
        "default": [
          "label",
          "name",
          "title",
          "Label",
          "Name",
          "Title"
        ],
        "arg": "titles_by_field",
        "env": "GRAPHISTRY_TITLES_BY_FIELD"
      }
    },
    "icons": {
      "doc": "JSON dictionary from entity type to icon name:\n                { \"myType\": \"car\", ... }",
      "default": {},
      "arg": "icons",
      "env": "GRAPHISTRY_ICONS"
    },
    "colors": {
      "doc": "JSON dictionary from entity type to color hex code:\n                { \"myType\": \"#FF0000\", ... }",
      "default": {},
      "arg": "colors",
      "env": "GRAPHISTRY_COLORS"
    },
    "sizes": {
      "doc": "JSON dictionary from entity type to size integers (1-1000), with Graphistry using 40/80/100/150:\n                { \"myType\": 100, ... }",
      "default": {},
      "arg": "sizes",
      "env": "GRAPHISTRY_SIZES"
    },
    "products": {
      "doc": "JSON array of per-product encoding dictionaries (field \"name\" mandatory):\n                [\n                    {\n                        name: String, // unique friendly name\n                        ? productIdentifier: {\"field1\": \"value1\", ...}, // index selector\n                        ? fieldsBlacklist: [ \"field1\", ... ], //exclude from data extraction\n                        ? attributesBlacklist: [ \"field1\", ... ], //exclude from entity drilldown\n                        ? entitiesBlacklist: [ \"field1\", ... ], //exclude from generated nodes\n                        ? defaultFields: [ \"field1\", ... ], //populate dropdowns\n                        ? desiredEntities: [ \"field1\", ...], //default nodes\n                        ? desiredAttributes: [ \"field1\", ...], //default drilldowns\n                        ? colTypes: { \"col1\": \"type1\", ... } //what node type to generate from a column\n                    },\n                ... ]",
      "format": "products",
      "default": [],
      "arg": "products",
      "env": "GRAPHISTRY_PRODUCTS"
    }
  },
  "pivotApp": {
    "mountPoint": {
      "doc": "Pivot mount point",
      "default": "/pivot",
      "arg": "pivot-mount-point",
      "env": "PIVOT_MOUNT_POINT"
    },
    "cachePoint": {
      "doc": "Nginx caching point",
      "default": "/cached",
      "arg": "pivot-cache-point",
      "env": "PIVOT_CACHE_POINT"
    },
    "dataDir": {
      "doc": "Directory to store investigation files",
      "default": "data",
      "arg": "pivot-data-dir",
      "env": "PIVOT_DATA_DIR"
    }
  },
  "log": {
    "level": {
      "doc": "Log levels - ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']",
      "format": [
        "TRACE",
        "DEBUG",
        "INFO",
        "WARN",
        "ERROR",
        "FATAL"
      ],
      "default": "INFO",
      "arg": "log-level",
      "env": "GRAPHISTRY_LOG_LEVEL"
    },
    "file": {
      "doc": "Log so a file intead of standard out",
      "arg": "log-file",
      "env": "LOG_FILE"
    },
    "logSource": {
      "doc": "Logs line numbers with debug statements. Bad for Perf.",
      "default": false,
      "arg": "log-source",
      "env": "LOG_SOURCE"
    }
  },
  "graphistry": {
    "key": {
      "doc": "Graphistry's api key",
      "arg": "graphistry-key",
      "env": "GRAPHISTRY_KEY",
      "sensitive": true
    },
    "host": {
      "doc": "The location of Graphistry's Server",
      "default": "http://graphistry",
      "arg": "graphistry-host",
      "env": "GRAPHISTRY_HOST"
    }
  },
  "pivots": {
    "show": {
      "doc": "Pivots to show; undefined means all. See load sequence output for available options. Ex: search-splunk-fireeye-botnet-demo,expand-fireeye-botnet-demo",
      "arg": "pivots-show",
      "env": "PIVOTS_SHOW"
    },
    "hide": {
      "doc": "Pivots to hide; undefined means none. See load sequence output for available options. Ex: search-splunk-fireeye-botnet-demo,expand-fireeye-botnet-demo",
      "arg": "pivots-hide",
      "env": "PIVOTS_HIDE"
    }
  },
  "neo4j": {
    "bolt": {
      "doc": "Neo4j BOLT endpoint, e.g., bolt://...:24786",
      "arg": "neo4j-bolt",
      "env": "NEO4J_BOLT"
    },
    "user": {
      "doc": "Neo4j user name",
      "arg": "neo4j-user",
      "env": "NEO4J_USER"
    },
    "password": {
      "doc": "Neo4j password",
      "arg": "neo4j-password",
      "env": "NEO4J_PASSWORD",
      "sensitive": true
    },
    "searchMaxTime": {
      "doc": "Maximum time (in milliseconds) allowed for executing a Neo4j search query.",
      "default": 20000,
      "arg": "neo4j-search-max-time",
      "env": "NEO4J_SEARCH_MAX_TIME"
    },
    "metadata": {
      "doc": "Transaction metadata",
      "arg": "neo4j-metadata",
      "env": "NEO4J_METADATA"
    },
    "schema": {
      "defaultTimeIndex": {
        "nodeProperties": {
          "doc": "Default node properties to time filter on when available (use as few as possible)",
          "default": [],
          "arg": "neo4j-time-fields-nodes",
          "env": "NEO4J_TIME_INDEX_NODES"
        },
        "relationshipProperties": {
          "doc": "Default relationship properties to time filter on when available (use as few as possible)",
          "default": [],
          "arg": "neo4j-time-fields-relationships",
          "env": "NEO4J_TIME_INDEX_RELATIONSHIPS"
        }
      },
      "inferSchema": {
        "doc": "Infer schema on system start (db.schema)",
        "default": true,
        "arg": "neo4j-infer-schema",
        "env": "NEO4J_INFER_SCHEMA"
      },
      "inferTimeout": {
        "doc": "Seconds after which to abandon each schema inference query",
        "default": 2,
        "arg": "neo4j-infer-timeout",
        "env": "NEO4J_INFER_TIMEOUT"
      },
      "labelProperties": {
        "doc": "Define label names and map name to list of property {name,type} pairs",
        "default": {},
        "arg": "neo4j-label-properties",
        "env": "NEO4J_LABEL_PROPERTIES"
      },
      "relationshipProperties": {
        "doc": "Define relationship names and map to list of property {name,type} pairs",
        "default": {},
        "arg": "neo4j-relationship-properties",
        "env": "NEO4J_RELATIONSHIP_PROPERTIES"
      },
      "textIndexes": {
        "doc": "Define text indexes to use for text searches. Format: \n[{ \n    description: str    \n    indexName: str\n    tokenNames: [ str ]\n    properties: [ str ]\n    type: \"node_fulltext\" | \"relationship_fulltext\"\n}, ...]                \n                ",
        "default": [],
        "arg": "neo4j-text-indexes",
        "env": "NEO4J_TEXT_INDEXES"
      }
    }
  },
  "elasticsearch": {
    "host": {
      "doc": "The hostname of the Elasticsearch Server",
      "arg": "es-host",
      "env": "ES_HOST"
    },
    "port": {
      "doc": "Elasticsearch port",
      "default": 9200,
      "arg": "es-port",
      "env": "ES_PORT"
    },
    "version": {
      "doc": "Elasticsearch version as major.minor (6.2, 5.6, ...), autodetects by default",
      "arg": "es-version",
      "env": "ES_VERSION"
    },
    "protocol": {
      "doc": "HTTP or HTTPS",
      "default": "http",
      "arg": "es-protocol",
      "env": "ES_PROTOCOL"
    },
    "auth": {
      "doc": "HTTP credentials -- user:password, or undefined",
      "arg": "es-auth",
      "env": "ES_AUTH"
    }
  },
  "vt": {
    "host": {
      "doc": "The VT host, you usually want to leave this alone",
      "default": "https://www.virustotal.com"
    },
    "fileReport": {
      "doc": "The file report path, you usually want to leave this alone",
      "default": "/vtapi/v2/file/report"
    },
    "key": {
      "doc": "The VT key, you might want one",
      "env": "VIRUSTOTAL_KEY",
      "sensitive": false
    }
  },
  "splunk": {
    "useProxy": {
      "doc": "Proxy through Graphistry agent instead of direct connection",
      "default": false,
      "arg": "splunk-use-proxy",
      "env": "SPLUNK_USE_PROXY"
    },
    "proxyKey": {
      "doc": "Key that the proxy must provide to confirm its identity; see server commands for how to generate",
      "arg": "splunk-proxy-key",
      "env": "SPLUNK_PROXY_KEY"
    },
    "serverKey": {
      "doc": "Token for checking server identity",
      "arg": "splunk-server-key",
      "env": "SPLUNK_SERVER_KEY"
    },
    "key": {
      "doc": "Splunk password",
      "default": "admin",
      "arg": "splunk-key",
      "env": "SPLUNK_KEY",
      "sensitive": true
    },
    "user": {
      "doc": "Splunk user name",
      "default": "admin",
      "arg": "splunk-user",
      "env": "SPLUNK_USER"
    },
    "host": {
      "doc": "The hostname of the Splunk Server (splunk.example.com)",
      "arg": "splunk-host",
      "env": "SPLUNK_HOST"
    },
    "port": {
      "doc": "Splunk API port",
      "default": 8089,
      "arg": "splunk-port",
      "env": "SPLUNK_PORT"
    },
    "uiPort": {
      "doc": "Splunk web UI port",
      "default": 443,
      "arg": "splunk-web-port",
      "env": "SPLUNK_WEB_PORT"
    },
    "scheme": {
      "doc": "Splunk protocol",
      "format": [
        "http",
        "https"
      ],
      "default": "https",
      "arg": "splunk-scheme",
      "env": "SPLUNK_SCHEME"
    },
    "suffix": {
      "doc": "Splunk url suffix, e.g., en-US in mysplunk.com/en-US/app/search",
      "default": "/en-US",
      "arg": "suffix",
      "env": "SPLUNK_SUFFIX"
    },
    "jobCacheTimeout": {
      "doc": "Time (in seconds) during which Splunk caches the query results. Set to -1 to disable caching altogether",
      "default": 14400,
      "arg": "splunk-cache-timeout",
      "env": "SPLUNK_CACHE_TIMEOUT"
    },
    "searchMaxTime": {
      "doc": "Maximum time (in seconds) allowed for executing a Splunk search query.",
      "default": 20,
      "arg": "splunk-search-max-time",
      "env": "SPLUNK_SEARCH_MAX_TIME"
    },
    "version": {
      "doc": "Splunk server version string (\"4.3.2\", \"5.0\"). Defaults to Splunk JavaScript SDK connector default.",
      "default": "",
      "arg": "splunk-version",
      "env": "SPLUNK_VERSION"
    },
    "other": {
      "doc": "Unsafe: Arbitrary additional paramemters to send to Splunk JavaScript SDK connector initialization",
      "default": {},
      "arg": "splunk-other",
      "env": "SPLUNK_OTHER"
    }
  }
}
```        

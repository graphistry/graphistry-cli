# Custom pivots

Graphistry supports creating new pivots. Adding custom pivots simplifies accessing new data sources and taking common actions. We strongly recommend leveraging custom pivots to simplify use for new and busy users!

The pivot system is constantly improving, so if you have requests or challenges, please do not hesitate to reach out. Combine custom pivots into sequences by [creating investigation templates](templates.md) from directly within the UI. See also the [convict-format schema](https://github.com/graphistry/graphistry-cli/blob/master/docs/configure-investigation.md#schema).

## Concepts and architecture

The extensible pivot system combines several parts:

* **Connectors**: Low-level APIs for communicating with HTTP, Splunk, Neo4j, and other systems with custom protocols. Instantiated with settings such as database credentials. Graphistry-provided with configuration by admins.

* **Pivots**: Visual components for interacting with the graph through connectors

  * **Base pivots**:  Generic and Graphistry-provided

  * **Derived pivots**: Added and customized by admins

* **Investigations**: User-configured instantiations of pivots that are chained together and run

## Connectors
Configuring a connector such as a Splunk will automatically enable it in the settings panel. See [main config docs](configure.md) and [investigation configuration](configure-investigation.md). Connectors get instantiated during system start, and may defer some initialization activity such database schema indexing. 

The built-in HTTP connector enables generic use of many web APIs for which Graphistry does not have a native connector. We are constantly adding and upgrading the system-provided connectors, and planning to expose user-defined connectors, so please contact if critical for your use case.

## Pivots

The investigation UI instantiates, configures, and runs pivots. Pivots can be both base pivots and derived pivots. Pivots work over the graph and a connector to generate new subgraphs that the investigation runner merges into the graph. When an investigation gets saved, it also saves its instantiated pivot settings, which you can inspect in `data/investigation/pivots/*.json`. 

## Base pivots

Each connector comes with several base pivots. Enabling a connector will cause its base pivots to load at start and appear as available pivots within an investigation.

System start logs will provide base pivot information. 

Ex:

```
Loaded pivot [expand-neo4j-neo4j-connector][Neo4j: Expand]
  Connector: [neo4j-connector][Neo4j]
  Parameters: 
    [ref][Any field in:]:pivotCombo - (undefined), visible: true,
    [pivotFields][Expand on types:]:multi - (undefined), visible: true,
    [targetTypes][Target node types:]:multi - (undefined), visible: true,
    ...
```

The above base pivot contains several parts:

* **ID**: Unique string `expand-neo4j-neo4j-connector`, typically detailing both the pivot action and the connector instance ID
* **Label**: Friendly UI-visible string `Neo4j: Expand` 
* **Parameters**: Base settings for controlling the pivot, both UI visible and not. Reference these when creating derived pivots. Each parameter has several fields:
  *  **name**: Identifier string unique within the parameter list
  *  **inputType**: String controlling form element type - `text`, `textarea`, `bool`, `multi`, and `combo`
  *  **defaultValue**: JSON based on *inputType*
  *  **isVisible**: Boolean flag whether to show in the UI
  *  **isSensitive**: Boolean flag whether to further restrict handling, such as for passwords
  *  Based on the *inputType*, additional fields, such as **label** and **options**

## Derived pivots

Derived pivots are new user-facing pivots generated by declaratively configuring base pivots. 

### Loading
Define declarative pivots as values in `config/pivot-db/config/config` under `{"systemTemplates": {"pivots": [ ... ]} }`. 

Upon success, system start logs will print:

* In debug mode:

```
Derived system pivot {
  id: 'neo4j-schema-neo4j-connector',
  ...
```

* Followed by, in production mode:

```
✅ Loaded pivot [neo4j-schema-neo4j-connector][Neo4j: View schema]...
```

### Overriding parameters

One of the most common use cases is creating derived pivots that simplify more general pivots by hard-coding default values and providing a slimmed down UI. 

For example, consider expanding based on IP. The base Splunk expand pivot `expand-splunk-plain` could be simplified via:

```json
{
	"id": "expand-splunk-ip",
	"name": "Splunk: Expand by IP",
	"template": "expand-splunk-plain",
	"parameters": [
	  {
	    "name": "pivotFields",
		 "defaultValue": ["src_ip", "dest_ip", "ip"]
	  },
	  {
	    "name": "colMatch",
	    "defaultValue": false
	  },
	  {
	    "name": "filter",
	    "defaultValue": "index=devices"
	  },
	  {
	    "name": "timeout",
	    "defaultValue": 10,
	    "visible": false
	  },
	  {
	    "name": "fuzzyMatchMode",
	    "defaultValue": false,
	    "visible": false
	  }
	]
}
```

The above creates a new derived pivot with more IP-specific default values than `expand-splunk-plain`. Most of the options are still exposed to the user in case they may want to change them, but parameters such as `fuzzyMatchMode` might not make sense to change for IP lookups. The result is a common action now has a preconfigured pivot that is faster and simpler to use.


### Macros


Macro-capable pivot parameters such as Splunk and Neo4j query strings will expand macro variables. This enables tasks such as embedding hidden passwords and combines powerfully with the ability to create new UI-driven parameter.

Macro variables are of two types:

* **parameter**: 
  
  Syntax: `{ *myParamName }`
  
  Expands to the current value of the corresponding named pivot parameter, or throws an error if no such parameter

  Example:

```json
{
  "id": "expand-splunk-ip",
  "name": "Splunk: Expand by IP",
  "template": "expand-splunk-plain",
  "parameters": [
    {
      "name": "filterPost",
      "defaultValue": "head { *max }"
    },
  ]
}
```  


* **config**

  Syntax: `{ .my.conf.parm }`
  
  Expands to the current value of the corresponding named configuration parameter, or throws an error if no such parameter or it is marked as sensitive
  
```json
{
  "id": "expand-splunk-searchhead",
  "name": "Splunk: Expand on searchhead",
	"template": "expand-splunk-plain",
	"parameters": [
      {
        "name": "filter",
        "defaultValue": "search host={ .splunk.host }"
      },
  ]
}
```  


### New parameters

You can add new UI parameters as well. For example, you can create a new pivot that is like `expand-splunk-plain` except also has new text parameter `myNewParam`:

```json
{
  "id": "expand-splunk-custom-param",
  "name": "Splunk: Expand on searchhead",
	"template": "expand-splunk-plain",
	"parameters": [
      {
        "name": "myNewParam",
        "inputType": "text",
        "label": "Put any string here:",
        "isVisible": true,
        "defaultValue": "hello",
      },
  ]
}
``` 

## Example: Splunk - Combining new parameters with macros

The power of new parameters comes through macros. For example, an IP search pivot can be reduced to a single user-visible parameter:


File `config/pivot-db/config/config.json`:

```json
{
  "systemTemplates": {
    "pivots": [
		{
		  "id": "search-splunk-IP",
		  "name": "Splunk: Lookup IP",
			"template": "search-splunk-plain",
			"parameters": [
		      {
		        "name": "ip",
		        "inputType": "text",
		        "label": "IP:",
		        "isVisible": true,
		        "defaultValue": "10.0.0.1",
		      },
		      {
		        "name": "filter",
		        "isVisible": false,
		        "defaultValue": "src_ip={ *ip }"
		      },
		      {
		        "name": "filterPost",
		        "isVisible": false
		      },
      ]
    }
    ]
  }
}
```

This pivot removes the need for users to know Splunk queries when doing IP searches!


## Example - Neo4j - Combining new parameters with macros

The following example reuses the Neo4j `search-neo4j` (Cypher query) pivot, where instead of forcing users to write raw Cypher queries for a common domain name lookup, they can just use a new `Domain` text entry button. Note the creation of a new input (`domain`) and the underlying `query` is set to `"isVisible": "false"` and uses the macro `{ *domain }`.

```json
{
  "systemTemplates": {
    "pivots": [
            {
                "id": "amass-domain-to-asn",
                "name": "Amass: Domain->ASNs",
                "template": "search-neo4j-neo4j-connector",
                "parameters": [
                    {
                        "name": "domain",
                        "inputType": "text",
                        "label": "Domain:",
                        "isVisible": true,
                        "defaultValue": "site.com"
                    },
                    {
                        "name": "query",
                        "isVisible": false,
                        "defaultValue": "MATCH (a)-[r:DOMAIN { domain: \"{ *domain }\" }]-(b) RETURN a, r, b"
                    },
                    {
                        "name": "max",
                        "defaultValue": 2000
                    }
                ]
            },
    ]
  }
}
```	    

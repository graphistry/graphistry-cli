# Configure PyGraphistry

PyGraphistry can be configured for tasks such as eliminating analyst boilerplate, customizing security handling, and supporting advanced server configurations.

Configuration is for two basic APIs: the upload API for how PyGraphistry sends data to a Graphistry server, and the client API for how a URL is loaded into a user's browser.

For server configuration, see [main configuration docs](configure.md). For REST API settings for uploading and viewing visualizations, see main developer documentation.

## The Cascade

PyGraphistry configuration settings resolve through the following cascade, with the top items overriding the further ones:

| Priority  | Name  | Primary Use  |
|:---:|:---|---|
| 5  | `graph.settings(url_params={...})`  | Analyst or developer fine-tuning an individual visualization's style via |
| 4  | `graphistry.register(...)`          | Analyst or developer  |
| 3  | Environment variables               | Developer or sysadmin |
| 2  | `graphistry.config`                 | Sysadmin              | 
| 1  | Default                             |                       |

Graphistry's built-in Jupyter server comes with a predefined `graphistry.config`.

## Settings

### General
| Setting | Default | Type | Description
|---|---|---|---|
| `api` | 1 | `1` _JSON_ <br> `2` _protobuf_ <br>` 3` (recommended: JWT+Arrow) | Upload format and wire protocol |
| `certificate_validation` | `True` | boolean | Unsafe: Disable to allow ignore TLS failures such as for known-faulty CAs |
| `client_protocol_hostname` | `None` | FQDN, including protocol, for overriding `protocol` and `hostname` for what URL is used in browsers from displaying visualizations |
| `hostname` | `"hub.graphistry.com"` | string | Domain (and optional path) for where to upload data and load visualizations
| `protocol` | `"https"` | `"https"` or `"http"` | |

### 1.0 API (DEPRECATED)

Deprecated 1.0 API option (api=1, api=2)

| Setting | Default | Type | Description
| `api_key` | `None` | string | *deprecated* |
| `dataset_prefix` | `"PyGraphistry/"` | string | *deprecated* Prefix on upload location |


## Usage Modes

### graph.settings(url_params={...})

Override and add query parameters to the loaded visualization iframe by adding key/value strings to `url_params`. This does not control the protocol, domain, nor path, so is primarily for styling and debugging purposes.

#### Example

```python
my_graph.settings(url_params={
    'play': '0', 
    'my_correlation_id': 'session-123'
}).plot()
```


### graphistry.register()

Note: Setup of the environment lets developers and analysts skip manually configuring `register()`, which may be preferrable

Global module settings can be defined via `register()`:

```
register(api=3, username='...', password='...', server=None, protocol=None, api=None, certificate_validation=None, ...)
```

See PyGraphistry docs for individual connectors such as `.bolt(...)` and `.tigergraph(...)`.

#### Example: Neo4j (bolt/cypher)

```python
import graphistry
graphistry.register(api=3, username='...', password='...', protocol='http', server='my.server.com')

g = graphistry.bolt({'server': 'bolt://...', 'auth': ('my_user', 'my_pwd')})

g.cypher("MATCH (a)-[b]->(c) RETURN a,b,c LIMIT 10").plot()
g.cypher("MATCH (a)-[b]->(c) RETURN a,b,c LIMIT 100000").plot()
...
```

### Environment variables

#### General

| Graphistry Setting | Environment Variable | Description |
|:---|:---|:---|
| `api_version` | `GRAPHISTRY_API_VERSION` ||
| `certificate_validation` | `GRAPHISTRY_CERTIFICATE_VALIDATION` ||
| `client_protocol_hostname` | `GRAPHISTRY_CLIENT_PROTOCOL_HOSTNAME` ||
| `hostname` | `GRAPHISTRY_HOSTNAME` ||
| `protocol` | `GRAPHISTRY_PROTOCOL` ||
| | `PYGRAPHISTRY_CONFIG` | Absolute path of `graphistry.config`

#### 1.0 API (DEPRECATED)

| Graphistry Setting | Environment Variable | Description |
|:---|:---|:---|
| `api_key` | `GRAPHISTRY_API_KEY` ||
| `dataset_prefix` | `GRAPHISTRY_DATASET_PREFIX` ||

There are multiple common ways to set environment variables:

* OS user login, e.g., `.bashrc` file
* In an invocation script, `MY_FLD=MY_VAL python myscript.py`
* The `environment:` section of Graphistry's `~/docker-compose.yml` for `notebook` or the `~/.env` file.
  WARNING: Editing `.env` is preferred over editing `.yml` in order to simplify upgrading
* In Python via `os.environ['MY_FLD'] = 'MY_VAL'`


### graphistry.config

Specify a `json` file using key/values from the Settings table.

PyGraphistry automatically checks for `graphistry.config` as follows:

```python
config_paths = [
    os.path.join('/etc/graphistry', '.pygraphistry'),
    os.path.join(os.path.expanduser('~'), '.pygraphistry'),
    os.environ.get('PYGRAPHISTRY_CONFIG', '')
]
```

## Graphistry Enterprise: Install packages into built-in Jupyter notebook 

If you are using Graphistry's built-in Jupyter server, it autoconfigures `PYGRAPHISTRY_CONFIG`, `graphistry.config`, and `PYTHONPATH`.

The `PYTHONPATH` is automatically set to correspond to your host's `data/py_envs/*` folders, so custom package installs will persist across container restarts and rebuilds.

### Install new packages

You can likely just `pip install you_package` and will work

Safety tip: Use `pip install --no-deps your_package` . This avoids risks of breaking existing GPU packages with unintended dependency upgrades.

You typically need to restart your Jupyter notebook's Python kernel after installing new packages.

### List custom package installs

Check on your host environment, `ls ./data/py_envs/*`

You may also be able to check via your Jupyter notebook environment. See `env` to find where the custom packages are mounted, and check that folder.

### Uninstall packages

Perform the usual `pip uninstall your_package` command.

If there are lingering file issues, check your `data/py_envs` folder for any unintended files and folders.

You may need to restart your Jupyter notebook's Python kernel after uninstalling packages to have the intended effect.

## Bundled installs

Graphistry Enterprise servers come with dependencies built-in, so you can skip this section

For custom environments, you may want to add some that PyGraphistry prebundles. Run `pip install graphistry[bundle_name]`, with the following bundle names as common ones:

* None: (`pip install graphistry`) - no extras
* `umap_learn`: For CPU UMAP support
* `ai`: For AI/ML support, including 1GB+ PyTorch install
* RAPIDS.AI: You can also get far by installing the RAPIDS.ai ecosystem, especially cudf, cuml, and cugraph
* For more options, see the `setup.py` file in the PyGraphistry Github repository


## Examples

### Speed up some uploads

```python
import graphistry
graphistry.register(api=3, username='..', password='...')
```

### Preset a 1.0 API key for all system users

Create Python-readable `/etc/graphistry/.pygraphistry`:

```json
{
    "api_key": "SHARED_USERS_KEY", 
    "protocol": "https",
    "hostname":"my.server.com"
}
```

For Jupyter notebooks, you may want to create per-user login `.pygraphistry` files. Please contact staff for further options and requests.

###  Different URLs for internal upload vs external viewing

In scenarios like Graphistry running on a notebook server, you may prefer to send uploads to a local host (`http://localhost`, `http://nginx`, ...), and tell browser client viewers to use a separate, public host and subpath (`http://graphistry.site.ngo/graphistry`):

```python
import os
import graphistry

### Internal URL: PyGraphistry app -> Graphistry Server
GRAPHISTRY_HOSTNAME_PROTOCOL='https'
os.environ['GRAPHISTRY_HOSTNAME'] = "localhost"

### External URL: Webpage iframe URL -> Graphistry Server
os.environ['GRAPHISTRY_CLIENT_PROTOCOL_HOSTNAME'] = "https://graph.site.ngo/graphistry"

graphistry.register(
    key='MY_API_KEY',
    protocol=GRAPHISTRY_HOSTNAME_PROTOCOL
)
```



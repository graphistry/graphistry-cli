# Configure the Python Endpoing

The Python endpoint allows any user granted access a way to retrieve datasets stored within Graphistry and process it using unrestricted arbitrary user provided Python code. This Python code can include a limited set of external libraries such as `numpy` and `cudf`, in addition to `graphistry`, and can access all computational resources available to the forge-etl-python server including GPU compute. The result is returned to the user as a string or as JSON.

## Safe defaults

* Graphistry Hub: The Python endpoint is not available to Graphistry Hub users at this time

* Graphistry Enterprise: The Python endpoint must be explicitly turned on for regular Graphistry Enterprise users

The more restricted GFQL endpoint is default-on for both Graphistry Hub and Graphistry Enterprise

## Toggling

The endpoint must be both on in general, and individual user types explicitly allowed:

1. Enable access to individual users via the Graphistry admin panel's feature flag area

1. The flag must also be enabled at the system-level via the `ENABLE_PYTHON_ENDPOINT` environment variable in `data/config/custom.env`

We recommend checking individual user access before enabling the endpoint.

## Further reading

See also:

* The [Graphistry REST API for the Python endpoint](https://hub.graphistry.com/docs/Python/python-api/)
* The [Graphistry REST API for the GFQL endpoint](https://hub.graphistry.com/docs/GFQL/gfql-api/)

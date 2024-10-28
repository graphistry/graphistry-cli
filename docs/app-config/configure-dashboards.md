# Configure Dashboards

Graphistry maintains [graph-app-kit](http://github.com/graphistry/graph-app-kit), which extends [Streamlit](https://streamlit.io/) with Docker, multi-app, graph, and other practical extensions.

## Default configuration

### Public dashboards

* Publicly available at `public/dash/` (note the trailing slash)
* Files stored at `./data/public_views`
* Web editing: Users with Jupyter notebook access can edit views in the Jupyter folder `graph-app-kit-public`

### Private dashboards

* Available to site staff at `private/dash/` (note the trailing slash)
* Files stored at `./data/private_views`
* Web editing: Users with Jupyter notebook access can edit views in the Jupyter folder `graph-app-kit-private`

## Disable dashboards

1. Remove one or both dashboards from the menus: 
   * Go to the admin dashboard: `django-waffle` -> `flags` -> `flag_show_{public,private}_dashboard`
   * Set `Everyone` to `No`
   * `Save`

2. Disable the dashboard services:
   * Edit your `docker-compose.override.yml`
   * Services: `graph-app-kit-public` and `graph-app-kit-private`

## Add or modify python libraries

Python libraries can be added or modified as desired. See [graph-app-kit documentation](https://github.com/graphistry/graph-app-kit/blob/master/docs/additional-packages.md) for more information on how to use this feature.

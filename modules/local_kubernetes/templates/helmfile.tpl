# Generated bootstrap Helmfile. You can edit or replace this file later.
repositories:
  - name: cave
    url: https://caveconnectome.github.io/cave-helm-charts/

# Copy this file to helmfile.yaml and add your own overrides next to the *.defaults.yaml files
# e.g. create materialize.yaml to override values in materialize.defaults.yaml

# TODO update this


releases:
  - name: edge
    namespace: default
    chart: cave/edge
    version: 0.3.0
    values:
      - ${cluster_values}
      # Optionally override edge values in edge.yaml
      # - edge.yaml

  - name: materialization-engine
    namespace: default
    chart: cave/materializationengine
    version: 5.23.1-r4
    values:
      - ${cluster_values}
      - ${materialize_defaults}
      - materialize.yaml   # user override (schedules.json reference scaffolded by template)
      - ${annotation_defaults}
      - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: annotation-engine
    namespace: default
    chart: cave/annotationengine
    version: 4.41.4
    values:
      - ${cluster_values}
      - ${annotation_defaults}
      - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: pychunkedgraph
    namespace: default
    chart: cave/pychunkedgraph
    version: 2.20.0-r3
    values:
      - ${cluster_values}
      - ${pychunkedgraph_defaults}
      # - pychunkedgraph.yaml # optional user override

  - name: pcgl2cache
    namespace: default
    chart: cave/pcgl2cache
    version: 1.3.1-dev.4
    values:
      - ${cluster_values}
      - ${pcgl2cache_defaults}
      # - pcgl2cache.yaml    # optional user override

  - name: skeletoncache
    namespace: default
    chart: cave/skeletoncache
    version: 0.22.50-r1
    values:
      - ${cluster_values}
      - ${skeletoncache_defaults}
      # - skeletoncache.yaml  # optional user override

  - name: dash
    namespace: default
    chart: cave/dash
    version: 1.14.6
    values:
      - ${cluster_values}
      - ${dash_defaults}
      # - dash.yaml          # need to configure secretKey and python config file

  - name: authinfo
    namespace: default
    chart: cave/authinfo
    version: 0.1.0
    values:
      - ${cluster_values}
      # - authinfo.yaml      # must fill in supported datastacks

  - name: swaggerui
    namespace: default
    chart: cave/swaggerui
    version: 0.1.0
    values:
      - ${cluster_values}

  - name: landingpage
    namespace: default
    chart: cave/landingpage
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${landingpage_defaults}
      # - landingpage.yaml   # optional user override (e.g. custom service list)

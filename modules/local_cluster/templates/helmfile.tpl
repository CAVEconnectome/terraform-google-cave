# Generated bootstrap Helmfile. You can edit or replace this file later.
repositories:
  - name: cave
    url: https://caveconnectome.github.io/cave-helm-charts/

# Copy this file to helmfile.yaml and add your own overrides next to the *.defaults.yaml files
# e.g. create materialize.yaml to override values in materialize.defaults.yaml

releases:
  - name: edge
    namespace: default
    chart: cave/edge
    version: 0.2.0
    values:
      - ${cluster_values}
      # Optionally override edge values in edge.yaml
      # - edge.yaml

  - name: materialization-engine
    namespace: default
    chart: cave/materializationengine
    version: 5.12.0
    values:
      - ${cluster_values}
      - ${materialize_defaults}
      - materialize.yaml   # user override (schedules.json reference scaffolded by template)
      - ${annotation_defaults}
      # - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: annotation-engine
    namespace: default
    chart: cave/annotationengine
    version: 4.32.0
    values:
      - ${cluster_values}
      - ${annotation_defaults}
      # - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: pychunkedgraph
    namespace: default
    chart: cave/pychunkedgraph
    version: 0.2.3
    values:
      - ${cluster_values}
      - ${pychunkedgraph_defaults}
      # - pychunkedgraph.yaml # optional user override

  - name: pcgl2cache
    namespace: default
    chart: cave/pcgl2cache
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${pcgl2cache_defaults}
      # - pcgl2cache.yaml    # optional user override

  - name: skeletoncache
    namespace: default
    chart: cave/skeletoncache
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${skeletoncache_defaults}
      # - skeletoncache.yaml  # optional user override

  - name: dash
    namespace: default
    chart: cave/dash
    version: 0.2.2
    values:
      - ${cluster_values}
      - ${dash_defaults}
      # - dash.yaml          # optional user override

  - name: authinfo
    namespace: default
    chart: cave/authinfo
    version: 0.1.0
    values:
      - ${cluster_values}
      # - authinfo.yaml      # must fill in supported datastacks

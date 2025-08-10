# Generated bootstrap Helmfile. You can edit or replace this file later.
repositories:
  - name: cave
    url: https://caveconnectome.github.io/cave-helm-charts/
  - name: ingress-nginx
    url: https://kubernetes.github.io/ingress-nginx
  - name: jetstack
    url: https://charts.jetstack.io

# Copy this file to helmfile.yaml and add your own overrides next to the *.defaults.yaml files
# e.g. create materialize.yaml to override values in materialize.defaults.yaml

releases:
  - name: ingress-nginx
    namespace: kube-system
    chart: ingress-nginx/ingress-nginx
    version: 4.1.2
    values:
      - ${cluster_values}

  - name: cert-manager
    namespace: cert-manager
    chart: jetstack/cert-manager
    version: 1.9.1
    values:
      - ${cluster_values}

  - name: materialization-engine
    namespace: default
    chart: cave/materializationengine
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${materialize_defaults}
      # - materialize.yaml   # optional user override
      - ${annotation_defaults}
      # - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: annotation-engine
    namespace: default
    chart: cave/annotationengine
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${annotation_defaults}
      # - annotation.yaml    # optional user override
      - ${cloudsql_defaults}
      # - cloudsql.yaml      # optional user override

  - name: pychunkedgraph
    namespace: default
    chart: cave/pychunkedgraph
    version: 0.1.0
    values:
      - ${cluster_values}
      # - pychunkedgraph.yaml # optional user override

  - name: dash
    namespace: default
    chart: cave/dash
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${dash_defaults}
      # - dash.yaml          # optional user override

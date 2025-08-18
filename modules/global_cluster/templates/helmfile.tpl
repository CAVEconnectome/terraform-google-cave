repositories:
  - name: cave
    url: https://caveconnectome.github.io/cave-helm-charts/

# Copy this file to helmfile.yaml and add your own overrides next to the *.defaults.yaml files

releases:
  - name: authinfo
    namespace: default
    chart: cave/authinfo
    version: 0.1.0
    values:
      - ${cluster_values}
  - ${cloudsql_defaults}
      - ${authinfo_defaults}
      # - authinfo.yaml      # optional user override (set supportedDatastacks)

  - name: auth
    namespace: default
    chart: cave/auth
    version: 0.1.0
    values:
      - ${cluster_values}
      - ${cloudsql_defaults}
      - auth.defaults.yaml
      # - auth.yaml          # optional user override (secrets, scaling)

  # The following global services exist in legacy scripts but do not yet have charts in cave-helm-charts.
  # Add these releases if you want to deploy the rest of the global stack:
  # - name: auth
  #   chart: cave/auth
  #   values:
  #     - ${cluster_values}
  #     - ${cloudsql_defaults}
  #     - auth.defaults.yaml
  # - name: infoservice
  #   chart: cave/infoservice
  #   values:
  #     - ${cluster_values}
  #     - ${cloudsql_defaults}
  #     - infoservice.defaults.yaml
  # - name: nglstate
  #   chart: cave/nglstate
  #   values:
  #     - ${cluster_values}
  #     - nglstate.defaults.yaml
  # - name: emannotationschemas
  #   chart: cave/emannotationschemas
  #   values:
  #     - ${cluster_values}
  #     - emannotationschemas.defaults.yaml

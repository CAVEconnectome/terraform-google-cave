kubeContext: gke_${project_id}_${zone}_${cluster}
projectName: ${project_id}
cluster:
  cluster: "${cluster}"
  globalServer: "${global_server}"
  cluster_prefix: "${cluster_prefix}"
  environment: "${environment}"
  domainName: "${domain_name}"
  googleProject: "${project_id}"
  dataProjectName: "${data_project_id}"
  googleRegion: "${region}"
  googleZone: "${zone}"
  standardPool: "${standard_pool_name}"
  lightweightPool: "${lightweight_pool_name}"
  meshPool: "${mesh_pool_name}"
  dockerRegistry: "${docker_registry}"
  # Optional list of DNS hostnames used by Ingresses; generated from Terraform var.dns_entries
  dns_entries:
%{ for h in dns_entries ~}
    - "${h}"
%{ endfor ~}

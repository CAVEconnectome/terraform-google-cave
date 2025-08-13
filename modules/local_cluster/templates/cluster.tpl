kubeContext: gke_${project_id}_${zone}_${cluster}
projectName: ${project_id}
cluster:
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

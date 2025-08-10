# Generated values for PyChunkedGraph
limiter:
  redis:
    host: "${redis_host}"
cluster:
  globalServer: ""
  environment: "${environment}"
  domainName: "${domain_name}"
  googleProject: "${project_id}"
  dataProjectName: "${data_project_id}"
  googleRegion: "${region}"
  googleZone: "${zone}"
  standardPool: "${standard_pool_name}"
  dockerRegistry: "${docker_registry}"
pychunkedgraph:
  graphIds: ""
  secretFiles:
    - name: google-secret.json
      value: ""
    - name: cave-secret.json
      value: ""
  config: ""
  redis:
    host: "${redis_host}"
    port: 6379
  bigtableInstanceName: "${bigtable_instance}"
  writeMinReplicas: 1
  writeMaxReplicas: 3
  writeMemGb: 4
  writeCpuMilli: 500
  readMinReplicas: 1
  readMaxReplicas: 10
  readMemGb: 1.8
  readCpuMilli: 125
  meshMinReplicas: 1
  meshMaxReplicas: 3
  meshMemGb: 4
  meshCpuMilli: 1000
  meshWorkerMinReplicas: 1
  meshWorkerMaxReplicas: 10
  remeshQueue: 
  enableLogs: "enable"
  logsLeavesMany: ""

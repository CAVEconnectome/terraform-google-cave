# Generated values for PyChunkedGraph
limiter:
  redis:
    host: "${redis_host}"
pychunkedgraph:
  graphIds: ""
  secretFiles:
    - name: google-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${pycg_sa_secret}"
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
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
  meshWorkerMinReplicas: 0
  meshWorkerMaxReplicas: 10
  remeshQueue:
  enableLogs: "enable"
  logsLeavesMany: ""

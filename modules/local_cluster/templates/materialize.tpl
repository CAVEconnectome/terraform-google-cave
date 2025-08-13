# Generated values for Materialization Engine
materialize:
  schedules: []
  redis:
    host: "${redis_host}"
  secretFiles:
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
limiter:
  redis:
    host: "${redis_host}"
cloudsql:
  projectId: "${project_id}"
  instance: "${sql_instance_name}"

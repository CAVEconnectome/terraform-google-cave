# Generated values for Annotation Engine
limiter:
  redis:
    host: "${redis_host}"
annotation:
  secretFiles:
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
cloudsql:
  projectId: "${sql_project_id}"

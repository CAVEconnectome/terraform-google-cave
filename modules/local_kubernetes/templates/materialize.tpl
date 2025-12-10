# Generated values for Materialization Engine
materialize:
  schedules: []
  redis:
    host: "${redis_host}"
  secretFiles:
    - name: google-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${pycg_sa_secret}"
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
%{ if materialization_upload_bucket_name != "" ~}
  uploadBucketName: "${materialization_upload_bucket_name}"
%{ endif ~}
%{ if materialization_dump_bucket_name != "" ~}
  dumpBucketName: "${materialization_dump_bucket_name}"
%{ endif ~}
limiter:
  redis:
    host: "${redis_host}"
cloudsql:
  projectId: "${project_id}"
  instance: "${sql_instance_name}"

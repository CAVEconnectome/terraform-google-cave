# Generated values for Catalog service
catalog:
  datastacks: ${jsonencode(datastacks)}
  secretFiles:
    - name: google-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${catalog_sa_secret}"
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
cloudsql:
  sqlInstanceName: "${sql_instance_name}"

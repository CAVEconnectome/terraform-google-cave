nglstate:
  secretFiles:
    - name: google-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${nglstate_sa_secret}"
    - name: cave-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${cave_secret_name}"
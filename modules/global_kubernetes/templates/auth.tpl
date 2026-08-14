auth:
  secretFiles:
    - name: google-secret.json
      value: "ref+gcpsecrets://${secrets_project_id}/${auth_sa_secret}"

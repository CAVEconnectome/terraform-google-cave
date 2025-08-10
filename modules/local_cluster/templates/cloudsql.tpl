# Generated values for Cloud SQL connectivity
cloudsql:
  sqlInstanceName: "ref+tfstate+${terraform_state_url}/sql_instance_name"
  username: "ref+gcpsecrets://${secrets_project_id}/${postgres_credentials}#username"
  password: "ref+gcpsecrets://${secrets_project_id}/${postgres_credentials}#password"

# Generated values for Cloud SQL connectivity
cloudsql:
  sqlInstanceName: "ref+tfstate:${terraform_state_url}/output.sql_instance_name"
  username: "ref+gcpsecrets://${secrets_project_id}/${postgres_credentials}#username"
  password: "ref+gcpsecrets://${secrets_project_id}/${postgres_credentials}#password"
  googleSecret: "ref+gcpsecrets://${secrets_project_id}/${cloudsql_sa_secret}"

cloudsql:
  sqlInstanceName: "ref+tfstate${terraform_state_url}/sql_instance_name"
  username: "ref+gcpsecrets://${project}/${postgres_credentials}#username"
  password: "ref+gcpsecrets://${project}/${postgres_credentials}#password"

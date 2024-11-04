cloudsql:
  sqlInstanceName: "ref+tfstate${terraform_state_url}/sql_instance_name"
  username: "ref+tfstate${terraform_state_url}/postgres_user"
  password: "ref+tfstate${terraform_state_url}/postgres_password"
gcloud auth application-default login
export INSTANCE_CONNECTION_NAME={{cookiecutter.project_id}}:{{cookiecutter.region}}:{{cookiecutter.local_sql_instance_name}}

docker pull gcr.io/cloudsql-docker/gce-proxy:1.16
docker rm --force gce-proxy
docker rm --force adminer
docker run -d \
-v $HOME/.config/gcloud/:/config \
  -p 127.0.0.1:5432:5432 \
  --name gce-proxy \
  gcr.io/cloudsql-docker/gce-proxy:1.16 /cloud_sql_proxy \
  -instances=$INSTANCE_CONNECTION_NAME=tcp:0.0.0.0:5432 -credential_file=/config/application_default_credentials.json
docker run --link gce-proxy:db -p 8080:8080 --name adminer adminer

# terraform-google-cave
A repository to store terraform modules for setting up infrastructure as code for CAVE in google cloud


# setup
1. Install terraform
2. Install helm
3. make sure you can login to your google account, and you have a google project setup with the follwoing permissions on your account. 

service account user
kubernetes adminsitrator

4. This assumes you have setup bigtable and ingested some data into a table seperately.  This is currently managed by a seperate process documented and outlined in seung-lab/CAVEpipelines.  If you need to read more about how to format your segmentation result to be ingested look at thie markdown file [TODO: ADD LINK]

5. create a new environment in environments folder. Follow pattern found in example_environment.  Fill in values in the terraform.tfvars folder. 

Navigate to your environment folder with a terminal.

::
   terraform init

if this is a production environemnt, we reccomend setting up blue/green workspaces, so you can spin up a new workspace with no downtime when there are significant changes to the infrastructure beyond upgrading microservice versions. 

::
   terraform plan

If you have an existing deployment of CAVE that you would like to start managing with CAVE you will see a lot of resources being created here. To fix this you need to follow the instructions under the Migration section below. 

## Migration: 
If you already have a deployment
to get existing resources properly mapped into terraform that were created outside of it you need to import them 
from the environment folder.

postgres: 
terraform import module.infrastructure.google_sql_database_instance.postgres projects/<project_id>/instances/<cloudsql_instance_name>

i.e.
terraform import module.infrastructure.google_sql_database_instance.postgres projects/seung-lab/instances/svenmd-dynamicannotationframework-ltv

get sql instance names with  ``gcloud sql instances list``

postgres user:
terraform import module.infrastructure.google_sql_user.writer {GOOGLE_PROJECT_ID}/{SQL_INSTANCE_NAME}/{SQL_USER_NAME}
i.e.
terraform import module.infrastructure.google_sql_user.writer seung-lab/svenmd-dynamicannotationframework-ltv/postgres 

postgres ann database:
terraform import module.infrastructure.google_sql_database.annotation projects/<project_id>/instances/<sql_instance_id>/databases/annotation
i.e.
terraform import module.infrastructure.google_sql_database.annotation projects/seung-lab/instances/svenmd-dynamicannotationframework-ltv/databases/annotation

postgrea mat database:

## REDIS
The pychunkedgraph redis instance has cached data about which mesh fragments exist and which don't which helps accelerate the manifest generation for large oct-trees.  It's valuable to hydrate that cache with data from a precious production cache but must be done manually if you are re-running terraform in a new environment.. any data that is lost in the transition will be regenerated the next time it is queries so data integrity is not a huge concern. This information is just a cache

pcg redis:
terraform import module.infrastructure.google_redis_instance.pcg_redis projects/<project_id>/locations/<region>/instances/<pcg_redis_name>

i.e.
terraform import module.infrastructure.google_redis_instance.pcg_redis projects/seung-lab/locations/us-east1/instances/ltv-pcg-cache


## network
terraform import module.infrastructure.google_compute_network.vpc <project_id>/<network_name>
i.e.
terraform import module.infrastructure.google_compute_network.vpc seung-lab/daf-ltv5-network

## sub network

 terraform import module.infrastructure.google_compute_subnetwork.subnet <project_id>/<region>/<subnet-name>
 i.e.
terraform import module.infrastructure.google_compute_subnetwork.subnet seung-lab/us-east1/daf-ltv5-network-sub 




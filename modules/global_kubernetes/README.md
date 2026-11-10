two factor auth for auth
    - there is an auth info thing that auth uses in google cloud that make the two factor authentication work. 
    
    we have decided we need to make the oauth client manually and then upload that to a google secret manager with a specific name.  Then we reference that name in the terraform modules, and terraform will validate it at the cluster level in terms of making sure the json file contains all the proper DNS entries.

    we were in the midst of having claude set this up, making changes to the helm charts and the terraform modules to wire this up, we had not finished reviewing that work or testing it's flow. 

add service accounts for auth, info, nglstate
add google secret manager for those service account keys
wire up those keys to helm via the helm template files in global_kubernetes

wire up configuration settings that are created into the helm charts
review the global service helm charts for consistency with current 
CAVEdeployment templates

create/modify terragrunt import script to hydrate global infrastructure state
with existing infrastructure resources

make a script to read existing global variables and create a cookiecutter values file to facilitate migration
do a cookiecutter creating of global using this file
test global infrastructure import and terragrunt apply till we get minimal changes to existing infrastructure
spin up global cluster using terragrunt
run kubernetes module on that cluster
(make sure to remove global dns so that we are only spinning up a new global cluster that isn't being used by anything)
attempt to configure and apply helmfile apply to global cluster

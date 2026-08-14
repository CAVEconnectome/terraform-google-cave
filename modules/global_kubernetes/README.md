two factor auth for auth
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

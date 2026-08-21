# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.8.1".
# Note the extra `/` after the protocol is required for the shorthand
# notation.

terraform { 
  source = {% if cookiecutter.local_modules_repo %}"../../../{{ cookiecutter.local_modules_repo }}/modules/local_infrastructure"{% else %}"tfr:///CAVEconnectome/cave/google//modules/local_infrastructure?version=0.2.0"{% endif %}
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

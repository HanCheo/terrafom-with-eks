# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders()
}


# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/common.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# init# init
terraform {
  source = "${dirname(find_in_parent_folders())}/modules/vpc"
}

inputs = {
  cidr             = "10.20.0.0/16"
  name             = "dev-sandbox"
  eks_cluster_name = "${include.envcommon.locals.cluster_name}"
}
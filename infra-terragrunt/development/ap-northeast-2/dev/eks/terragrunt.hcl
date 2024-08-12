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

# init
terraform {
  source = "${dirname(find_in_parent_folders())}/modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    id                 = "fake-vpc-id"
    private_subnet_ids = ["fake-subnet-id-1", "fake-subnet-id-2", "fake-subnet-id-3", "fake-subnet-id-4", "fake-subnet-id-5", "fake-subnet-id-6"]
  }
}

inputs = {
  source       = "./modules/eks"
  cluster_name = "${include.envcommon.locals.cluster_name}"
  vpc = {
    id         = dependency.vpc.outputs.id
    subnet_ids = dependency.vpc.outputs.private_subnet_ids
  }
  default_node_group_instance = {
    ami_type       = "AL2_ARM_64"
    disk_size      = 10
    instance_types = ["t4g.large"]
  }
}
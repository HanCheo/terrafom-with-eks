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
  source = "${dirname(find_in_parent_folders())}/modules/helm"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name      = "fake-cluster-name"
    oidc_provider_arn = "fake-oidc-provider-arn"
    cluster_endpoint  = "fake-cluster-endpoint"
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    id = "fake-vpc-id"
  }
}


inputs = {
  alb-controller = {
    vpc = {
      id = dependency.vpc.outputs.id
    }

    region = "ap-northeast-2"


    eks = {
      cluster_name      = dependency.eks.outputs.cluster_name
      oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
      cluster_endpoint  = dependency.eks.outputs.cluster_endpoint
    }

    env = "${include.envcommon.locals.env}"
  }

  karpenter = {
    cluster_name      = dependency.eks.outputs.cluster_name
    oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
    cluster_endpoint  = dependency.eks.outputs.cluster_endpoint

    env = "${include.envcommon.locals.env}"
  }
}

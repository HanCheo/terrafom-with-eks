# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  account_name          = local.account_vars.locals.account_name
  account_id            = local.account_vars.locals.aws_account_id
  aws_access_key_id     = local.account_vars.locals.aws_access_key_id
  aws_secret_access_key = local.account_vars.locals.aws_secret_access_key
  aws_region            = local.region_vars.locals.aws_region
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}


provider "aws" {
  region = "${local.aws_region}"
  access_key = "${local.aws_access_key_id}"
  secret_key = "${local.aws_secret_access_key}"
  # Only these AWS Account IDs may be operated on by this template
  # allowed_account_ids = ["${local.account_id}"]
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    // encrypt = true
    // bucket         = "${get_env("TG_BUCKET_PREFIX", "")}terragrunt-example-tf-state-${local.account_name}-${local.aws_region}"
    // TODO Need replace
    bucket = "moby-sandbox-terraform-state"
    key    = "${path_relative_to_include()}/tf.tfstate"
    region = local.aws_region
    // dynamodb_table = "tf-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure what repos to search when you run 'terragrunt catalog'
// catalog {
//   urls = [
//     "https://github.com/gruntwork-io/terragrunt-infrastructure-modules-example",
//     "https://github.com/gruntwork-io/terraform-aws-utilities",
//     "https://github.com/gruntwork-io/terraform-kubernetes-namespace"
//   ]
// }

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
// inputs = merge(
//   local.account_vars.locals,
//   local.region_vars.locals,
//   local.environment_vars.locals,
// )
terraform {
  backend "s3" {
    bucket = "moby-sandbox-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = "ap-northeast-2"
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

module "vpc" {
  source           = "./modules/vpc"
  cidr             = "10.20.0.0/16"
  name             = "dev-sandbox"
  eks_cluster_name = "dev-sandbox-eks"
}
module "eks" {
  source       = "./modules/eks"
  cluster_name = "dev-sandbox-eks"
  vpc = {
    id         = module.vpc.aws_vpc.id
    subnet_ids = module.vpc.private_subnet_ids
  }
  default_node_group_instance = {
    ami_type       = "AL2_ARM_64"
    disk_size      = 10
    instance_types = ["t4g.large"]
  }
}

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "mobilog.me"
#   validation_method = "DNS"

#   tags = {
#     Environment = "test"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

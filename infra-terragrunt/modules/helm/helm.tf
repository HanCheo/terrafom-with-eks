module "karpenter" {
  source = "./karpenter"

  eks = {
    cluster_name      = var.karpenter.eks.cluster_name
    oidc_provider_arn = var.karpenter.eks.oidc_provider_arn
    cluster_endpoint  = var.karpenter.eks.cluster_endpoint
  }

  env = var.karpenter.env
}

module "alb-controller" {
  source = "./alb-controller"

  vpc = {
    id = var.vpc.id
  }

  region = var.alb-controller.region

  eks = {
    cluster_name      = var.alb-controller.eks.cluster_name
    oidc_provider_arn = var.alb-controller.eks.oidc_provider_arn
  }

  env = var.alb-controller.env
}

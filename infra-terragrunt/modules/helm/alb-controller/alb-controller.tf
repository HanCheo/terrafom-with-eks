locals {
  alb-controller-name = "aws-load-balancer-controller"
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.env}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = local.alb-controller-name
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = local.alb-controller-name
      "app.kubernetes.io/component" = "controller"
      "terraform"                   = "true"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "alb-controller" {
  name       = local.alb-controller-name
  repository = "https://aws.github.io/eks-charts"
  chart      = local.alb-controller-name
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc.id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.alb-controller-name
  }

  set {
    name  = "clusterName"
    value = var.eks.cluster_name
  }
}

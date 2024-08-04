data "aws_caller_identity" "current" {}

module "eks" {
	source = "terraform-aws-modules/eks/aws"
  version = "~> 20.20.0"

	cluster_name = var.cluster_name
	cluster_version = var.cluster_version

	cluster_endpoint_private_access = false
	cluster_endpoint_public_access = true

	include_oidc_root_ca_thumbprint = true
	enable_irsa = true

	vpc_id = var.vpc.id
	subnet_ids = var.vpc.subnet_ids
	
	iam_role_arn = var.cluster_arn
	create_iam_role = false

	enable_cluster_creator_admin_permissions = true

	cluster_addons = {
		kube-proxy = {
			more_recent = true
		}
    coredns                = {
			more_recent = true
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
		}
    eks-pod-identity-agent = {
			more_recent = true
		}
    vpc-cni                = {
			before_compute = true
			more_recent = true
		}
  }	

	eks_managed_node_group_defaults = var.default_node_group_instance

  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
    ("${var.cluster_name}") = {
      min_size     = 1
      max_size     = 5
      desired_size = 1
      labels = {
        ondemand = true
      }
    }
  }

  tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${var.cluster_name}"
  }
}


output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ap-northeast-2 update-kubeconfig --name ${var.cluster_name}"
}


module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.20.0"

  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.cluster_name
  create_pod_identity_association = true
}


################################################################################
# Helm charts
################################################################################

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = "0.36.2"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]

}

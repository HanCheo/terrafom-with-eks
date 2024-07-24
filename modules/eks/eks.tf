data "aws_caller_identity" "current" {}

module "eks" {
	source = "terraform-aws-modules/eks/aws"

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
    coredns                = {
			more_recent = true
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
    ("${var.cluster_name}") = {
      min_size     = 1 # 최소
      max_size     = 2 # 최대
      desired_size = 1 # 기본 유지

      labels = {
        ondemand = "true"
      }
    }
  }
}
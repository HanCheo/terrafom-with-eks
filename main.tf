provider "aws" {
	region = "ap-northeast-2"	
}
module vpc {
	source = "./modules/vpc"
	cidr = "10.20.0.0/16"
	name = "moby-sandbox"
}
module eks {
	source = "./modules/eks"
	cluster_name = "moby-sandbox-eks"
	vpc = {
		id = module.vpc.id
		subnet_ids = module.vpc.private_subnet_ids
	}

	default_node_group_instance = {
		ami_type = "AL2_x86_64"
		disk_size = 10
		instance_types = ["t3.xlarge"]
		node_group_arn = "arn:aws:iam::058264332540:role/OYG_ServiceRoleForAmazonEKSNodeGroup"
	}

	cluster_arn = "arn:aws:iam::058264332540:role/OYG_ServiceRoleForAmazonEKSCluster"
}
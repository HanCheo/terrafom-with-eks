variable "vpc" {
  type = object({
    id = string
  })
  description = <<EOT
		vpc = {
			id = vpc_id
		}
	EOT

}
variable "eks" {
  type = object({
    cluster_name      = string
    oidc_provider_arn = string
  })
  description = <<EOT
		eks = {
			cluster_name  		 = cluster_name
			oidc_provider_arn  = oidc_provider_arn
		}
	EOT
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "region" {
  type        = string
  description = "AWS region"
}

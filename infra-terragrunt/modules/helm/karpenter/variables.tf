variable "eks" {
  type = object({
    cluster_name      = string
    oidc_provider_arn = string
    cluster_endpoint  = string
  })
  description = <<EOT
		eks = {
			cluster_name  		 = cluster_name
			oidc_provider_arn  = oidc_provider_arn
			cluster_endpoint   = cluster_endpoint
		}
	EOT
}

variable "env" {
  type        = string
  description = "Environment"

}

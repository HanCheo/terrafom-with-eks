variable "alb-controller" {
  type = object({
    vpc = object({
      id = string
    })
    eks = object({
      cluster_name      = string
      oidc_provider_arn = string
    })
    env    = string
    region = string
  })
  description = "alb-controller variables"
}

variable "karpenter" {
  type = object({
    eks = object({
      cluster_name      = string
      oidc_provider_arn = string
      cluster_endpoint  = string
    })
    env = string
  })
  description = "karpenter variables"

}

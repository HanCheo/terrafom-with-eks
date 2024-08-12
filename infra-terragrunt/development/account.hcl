# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = "account_name"
  aws_account_id = "account_id" # TODO: replace me with your AWS account ID!

  # OR
  aws_access_key_id     = "aws_access_key_id"
  aws_secret_access_key = "aws_secret_access_key"
}
# This is a sample s3 bucket resource to demonstrate that the workspace can authenticate through Vault to AWS.

# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run/run-environment#environment-variables
variable "TFC_WORKSPACE_NAME" {}

variable "aws_region" {
  type        = string
  description = "The AWS region to manage resources in."
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current.user_id
}

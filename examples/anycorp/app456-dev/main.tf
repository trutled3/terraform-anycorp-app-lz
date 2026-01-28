# This is a sample s3 bucket resource to demonstrate that the workspace can authenticate through Vault to AWS.

# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run/run-environment#environment-variables
variable "TFC_WORKSPACE_NAME" {}

provider "aws" {}

data "aws_caller_identity" "current" {}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current.user_id
}

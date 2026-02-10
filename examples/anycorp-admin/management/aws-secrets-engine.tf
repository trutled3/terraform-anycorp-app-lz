# ---------------------------------------------------------------------------------------------#
# AWS Resources for Vault AWS Secrets Engine
# ---------------------------------------------------------------------------------------------#
# Provides an IAM user.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
resource "aws_iam_user" "secrets_engine" {
  name = "hcp-vault-secrets-engine"

  permissions_boundary = data.aws_iam_policy.demo_user_permissions_boundary.arn # remove
}

# Provides an IAM policy attached to a user. In this case, allowing the secrets_engine user rotate its own access key
#
# https://developer.hashicorp.com/vault/api-docs/secret/aws#rotate-root-iam-credentials
#
# Note that if the credentials are rotated, there will be drift in this Terraform configuration
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy
data "aws_iam_policy_document" "vault_secrets_engine_generate_credentials" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetUser",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys"
    ]
    resources = [aws_iam_user.secrets_engine.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    # for demo restrict any iam role in any account that ends with -tfe-role. the iam role will restrict whom it trusts.
    resources = ["arn:aws:iam::*:role/*-tfe-role"]
  }
}

resource "aws_iam_user_policy" "vault_secrets_engine_generate_credentials" {
  name = "hcp-vault-secrets-engine-policy"
  user = aws_iam_user.secrets_engine.name

  policy = data.aws_iam_policy_document.vault_secrets_engine_generate_credentials.json
}

# Provides an IAM access key. This is a set of credentials that allow API requests to be made as an IAM user.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key
resource "aws_iam_access_key" "secrets_engine_credentials" {
  # WARNING - The credentials this resource generateds will be written in plaintext in the statefiles for this configuration.
  # Protect the statefiles for this configuration accordingly!
  user = aws_iam_user.secrets_engine.name
}

# Creates an AWS Secret Backend for Vault. AWS secret backends can then issue AWS access keys and 
# secret keys, once a role has been added to the backend.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/aws_secret_backend
resource "vault_aws_secret_backend" "aws_secret_backend" {
  #   namespace = var.vault_namespace
  path = var.aws_secrets_backend_path

  # WARNING - These values will be written in plaintext in the statefiles for this configuration. 
  # Protect the statefiles for this configuration accordingly!
  access_key = aws_iam_access_key.secrets_engine_credentials.id
  secret_key = aws_iam_access_key.secrets_engine_credentials.secret
}

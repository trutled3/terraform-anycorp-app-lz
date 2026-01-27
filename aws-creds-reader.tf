data "vault_auth_backend" "tfe_jwt" {
  # namespace = var.vault_namespace
  path = var.vault_jwt_auth_path
}

#####################################################################
# TFE workspace run policy
#  - TFE workspaces must be able to renew and revoke their own tokens
#
# https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/vault-configuration#create-a-vault-policy
#####################################################################
data "vault_policy_document" "aws_secret_auth" {
  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
    description  = "Allow tokens to query themselves"
  }
  rule {
    path         = "auth/token/renew-self"
    capabilities = ["update"]
    description  = "Allow tokens to renew themselves"
  }
  rule {
    path         = "auth/token/revoke-self"
    capabilities = ["update"]
    description  = "Allow tokens to revoke themselves"
  }
  rule {
    path         = "${vault_aws_secret_backend.aws_secret_backend.path}/sts/${vault_aws_secret_backend_role.aws_secret_backend_role.name}"
    description  = "Allow to generate credentials from AWS Secrets Engine"
    capabilities = ["read"]
  }
}

resource "vault_policy" "aws_secret_auth" {
  name   = "aws-secret-auth"
  policy = data.vault_policy_document.aws_secret_auth.hcl
}


# Creates an AWS Secret Backend for Vault. AWS secret backends can then issue AWS access keys and 
# secret keys, once a role has been added to the backend.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/aws_secret_backend
resource "vault_aws_secret_backend" "aws_secret_backend" {
  #   namespace = var.vault_namespace
  path = "aws/${var.aws_account_id}"

  # WARNING - These values will be written in plaintext in the statefiles for this configuration. 
  # Protect the statefiles for this configuration accordingly!
  access_key = aws_iam_access_key.secrets_engine_credentials.id
  secret_key = aws_iam_access_key.secrets_engine_credentials.secret
}

# Creates a role on an AWS Secret Backend for Vault. Roles are used to map credentials to the policies 
# that generated them.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/aws_secret_backend_role
resource "vault_aws_secret_backend_role" "aws_secret_backend_role" {
  #   namespace       = var.vault_namespace
  backend         = vault_aws_secret_backend.aws_secret_backend.path
  name            = "terraform-operator"
  credential_type = "assumed_role"

  role_arns = [aws_iam_role.tfe_role.arn]
}

# ---------------------------------------------------------------------------------------------#
# AWS Resources for Vault AWS Secrets Engine
# ---------------------------------------------------------------------------------------------#
# Provides an IAM user.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
resource "aws_iam_user" "secrets_engine" {
  name = "hcp-vault-secrets-engine"
}

# Provides an IAM access key. This is a set of credentials that allow API requests to be made as an IAM user.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key
resource "aws_iam_access_key" "secrets_engine_credentials" {
  # WARNING - The credentials this resource generateds will be written in plaintext in the statefiles for this configuration.
  # Protect the statefiles for this configuration accordingly!
  user = aws_iam_user.secrets_engine.name
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
}

resource "aws_iam_user_policy" "vault_secrets_engine_generate_credentials" {
  name = "hcp-vault-secrets-engine-policy"
  user = aws_iam_user.secrets_engine.name

  policy = data.aws_iam_policy_document.vault_secrets_engine_generate_credentials.json
}

# Creates a role for the AWS Secrets Engine to assume for the sessions it generates. These are the permissions that you will 
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
data "aws_iam_policy_document" "tfe_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.secrets_engine.arn]
    }
  }
}

resource "aws_iam_role" "tfe_role" {
  name               = "tfe-role"
  assume_role_policy = data.aws_iam_policy_document.tfe_role_assume_role_policy.json
}

data "aws_iam_policy_document" "tfe_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "test_policy" {
  name   = "demo"
  role   = aws_iam_role.tfe_role.id
  policy = data.aws_iam_policy_document.tfe_role_policy.json
}

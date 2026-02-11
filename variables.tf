#---------------------------------------------------------------------------------#
# General Variables
#---------------------------------------------------------------------------------#
variable "app_name" {
  type = string
}

variable "environments" {
  type = list(string)

  validation {
    condition = alltrue([
      for v in var.environments : contains(["dev", "test", "prod"], v)
    ])

    error_message = "Valid environment values are: dev, test, prod."
  }
}

#---------------------------------------------------------------------------------#
# TFE Variables
#---------------------------------------------------------------------------------#
variable "tfe_vault_varset_name" {
  type        = string
  description = "The name of the TFE variable set that faciliates Vault backed dynamic credentials."
  default     = "vault-backed-dynamic-credentials"
}

#---------------------------------------------------------------------------------#
# AWS Variables
#---------------------------------------------------------------------------------#
variable "aws_account_id" {
  type        = string
  description = "The AWS Account ID for the App if using AWS. Leave blank if not using AWS."
}

variable "aws_iam_user_arn" {
  type        = string
  description = "The ARN of the IAM user created for the AWS Secrets Engine."
}

#---------------------------------------------------------------------------------#
# Vault Variables
#---------------------------------------------------------------------------------#
variable "vault_jwt_auth_path" {
  type        = string
  default     = "jwt"
  description = "The path where the JWT auth method is enabled in Vault."
}

variable "vault_namespace" {
  type        = string
  default     = "admin"
  description = "The namespace of the Vault instance you'd like to create the AWS and jwt auth backends in."
}

variable "aws_secret_backend_path" {
  type        = string
  description = "The mount path of the AWS secrets engine in Vault."
  default     = "aws"
}

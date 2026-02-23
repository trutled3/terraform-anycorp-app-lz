#---------------------------------------------------------------------------------#
# General Variables
#---------------------------------------------------------------------------------#
variable "app_name" {
  type = string
}

variable "environment" {
  type        = string
  description = "The environment of the app."

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
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

variable "tfe_vault_audience" {
  type        = string
  default     = "vault.workload.identity"
  description = "The audience claim that Vault will expect in the JWT presented by TFE when authenticating. This should be set to a value that makes sense for your organization and helps you identify the tokens in Vault."
}

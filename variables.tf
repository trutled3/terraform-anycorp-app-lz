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

variable "vault_jwt_auth_path" {
  type        = string
  default     = "jwt"
  description = "The path where the JWT auth method is enabled in Vault"
}

variable "tfe_vault_varset_name" {
  type        = string
  description = "The name of the TFE variable set that contains Vault backed dynamic credentials related variables."
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = "The AWS Account ID for the APM if using AWS. Leave blank if not using AWS."
}

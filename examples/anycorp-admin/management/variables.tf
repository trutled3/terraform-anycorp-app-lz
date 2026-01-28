variable "app_name" {
  type    = string
  default = "app456"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS Account ID for the APM if using AWS. Leave blank if not using AWS."
}

variable "environments" {
  type    = list(string)
  default = ["dev", "prod"]
}

variable "vault_jwt_auth_path" {
  type        = string
  default     = "jwt"
  description = "The path where the JWT auth method is enabled in Vault"
}

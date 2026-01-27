variable "app_name" {
  type    = string
  default = "app456"
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = "The AWS Account ID for the APM if using AWS. Leave blank if not using AWS."
}

variable "environments" {
  type    = list(string)
  default = ["dev", "prod"]
}

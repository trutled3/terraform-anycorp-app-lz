variable "app_name" {
  type = string
  default = "app456"
}

variable "environments" {
  type = list(string)
  default = [ "dev", "prod" ]
}
module "anycorp-app456-prod" {
  source = "./../../.."

  app_name       = "app-456"
  environment    = "prod"
  aws_account_id = "123456789012" # set by upstream
}

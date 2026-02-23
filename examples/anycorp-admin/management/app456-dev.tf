module "anycorp-app456-dev" {
  source = "./../../.."

  app_name       = "app-456"
  environment    = "dev"
  aws_account_id = "123456789012" # set by upstream
}

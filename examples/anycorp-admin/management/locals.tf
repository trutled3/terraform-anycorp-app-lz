locals {
  tfe_vault_varset_name = "" # the name of the variable set that bootstrapped workspaces use to connect to the Vault 
  vault_jwt_auth_path = "" # the mount path in Vault for the jwt auth method. only change this if there's already something mounted at /jwt
}
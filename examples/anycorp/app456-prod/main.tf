# This is just a dummy message to look at in TFE to make sure that the run happened.
# If Vault's Azure secrets engine is configured correctly, this App could use the azurerm provider to talk to Azure using the dynamic credentials
# provided to its workspace runs by TFE

resource "null_resource" "echo_message" {
  provisioner "local-exec" {
    command = "echo \"Prod environment infrastructure\""
  }
}

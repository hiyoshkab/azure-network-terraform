# Template assumes you have an existing Key Vault.
data "azurerm_key_vault" "existing" {
  name                = var.key_vault.name
  resource_group_name = var.key_vault.resource_group_name
}

locals {
  easy_auth_secret_name = regex("/secrets/([^/]+)$", var.key_vault_easyauth_secret_uri)[0]
}

resource "azurerm_role_assignment" "aca_easy_auth_secret_reader" {
  scope                = "${data.azurerm_key_vault.existing.id}/secrets/${local.easy_auth_secret_name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aca_umid.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "appgw_certificate_reader" {
  scope                = "${data.azurerm_key_vault.existing.id}/secrets/${regex("/secrets/([^/]+)$", var.key_vault_appgw_certificate_secret_uri)[0]}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw_umid.principal_id
  principal_type       = "ServicePrincipal"

  lifecycle {
    precondition {
      condition     = data.azurerm_key_vault.existing.rbac_authorization_enabled
      error_message = "The existing Key Vault must use Azure RBAC permissions."
    }

    precondition {
      condition     = startswith(var.key_vault_appgw_certificate_secret_uri, "${data.azurerm_key_vault.existing.vault_uri}secrets/")
      error_message = "The gateway certificate secret must be in the configured existing Key Vault."
    }
  }
}
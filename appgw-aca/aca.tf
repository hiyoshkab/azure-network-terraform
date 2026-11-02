# CAE System/Console Logs
resource "azurerm_log_analytics_workspace" "cae-laws" {
  name                = "appgw-aca-laws"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "aca_logs" {
  name                           = "aca-to-log-analytics"
  target_resource_id             = azurerm_container_app_environment.cae.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cae-laws.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }
}

# CAE
resource "azurerm_container_app_environment" "cae" {
  name                           = var.cae_name
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = var.location
  logs_destination               = "azure-monitor"
  internal_load_balancer_enabled = true
  public_network_access          = "Disabled"
  infrastructure_subnet_id       = azurerm_subnet.aca_subnet.id

  identity {
    type = "SystemAssigned"
  }

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

# ACA
# Need UMID to prevent circular dependency
resource "azurerm_user_assigned_identity" "aca_umid" {
  name                = "${var.aca_name}-umid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_container_app" "aca" {
  name                         = var.aca_name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "nginx"
      image  = "docker.io/nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    ip_security_restriction {
      name             = "application-gateway-only"
      action           = "Allow"
      ip_address_range = azurerm_subnet.appgw_subnet.address_prefixes[0]
    }
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_umid.id]
  }

  secret {
    name                = local.easy_auth_secret_name
    identity            = azurerm_user_assigned_identity.aca_umid.id
    key_vault_secret_id = var.key_vault_easyauth_secret_uri
  }

  depends_on = [azurerm_role_assignment.aca_easy_auth_secret_reader]
}

# Easy Auth
# App Registration
resource "azuread_application" "easy_auth_app_reg" {
  display_name     = "${azurerm_container_app.aca.name}-easyauth"
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = [
      "https://${var.custom_domain}/.auth/login/aad/callback"
    ]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}

# Service Principal
resource "azuread_service_principal" "easy_auth_sp" {
  client_id = azuread_application.easy_auth_app_reg.client_id
}

resource "azapi_resource" "easy_auth" {
  type      = "Microsoft.App/containerApps/authConfigs@2025-01-01"
  name      = "current"
  parent_id = azurerm_container_app.aca.id

  body = {
    properties = {
      platform = {
        enabled = true
      }

      globalValidation = {
        unauthenticatedClientAction = "RedirectToLoginPage"
        redirectToProvider          = "azureActiveDirectory"
      }

      httpSettings = {
        requireHttps = true
        forwardProxy = {
          convention            = "Custom"
          customHostHeaderName  = "X-Forwarded-Host"
          customProtoHeaderName = "X-Forwarded-Proto"
        }
      }

      identityProviders = {
        azureActiveDirectory = {
          enabled = true

          registration = {
            clientId                = azuread_application.easy_auth_app_reg.client_id
            clientSecretSettingName = local.easy_auth_secret_name
            openIdIssuer            = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
          }

          validation = {
            allowedAudiences = [
              azuread_application.easy_auth_app_reg.client_id
            ]
          }
        }
      }
    }
  }

  depends_on = [azuread_service_principal.easy_auth_sp]
}
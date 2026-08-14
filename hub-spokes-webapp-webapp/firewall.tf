# Data-plane public IP
resource "azurerm_public_ip" "fw_pip" {
  name                = "azfirewall-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_tags = {
    "FirstPartyUsage" = "/Unprivileged"
  }
}

# Management public IP (required for Basic tier)
resource "azurerm_public_ip" "fw_mgmt_pip" {
  name                = "azfirewall-mgmt-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_tags = {
    "FirstPartyUsage" = "/Unprivileged"
  }
}

# Firewall policy (required for Basic tier)
resource "azurerm_firewall_policy" "fw_policy" {
  name                = "azfirewall-policy"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
}

# Rule collection group holding the network rules
resource "azurerm_firewall_policy_rule_collection_group" "fw_rules" {
  name               = "spoke-to-spoke-rules"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allow-webapp1-to-webapp2"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "webapp1-to-webapp2"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/24"]
      destination_addresses = ["10.2.0.0/24"]
      destination_ports     = ["80", "443"]
    }
  }
}

# Azure FW
resource "azurerm_firewall" "azfirewall" {
  name                = "azfirewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  management_ip_configuration {
    name                 = "fw-mgmt-ipconfig"
    subnet_id            = azurerm_subnet.fwmgmt_hub.id
    public_ip_address_id = azurerm_public_ip.fw_mgmt_pip.id
  }
}

# Log Analytics workspace to receive firewall logs
resource "azurerm_log_analytics_workspace" "fw_law" {
  name                = "azfirewall-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 30
}

# Send Azure Firewall logs/metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "fw_diag" {
  name                           = "azfirewall-diag"
  target_resource_id             = azurerm_firewall.azfirewall.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.fw_law.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_log {
    category = "AZFWNatRule"
  }
}
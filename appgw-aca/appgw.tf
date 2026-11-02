resource "azurerm_user_assigned_identity" "appgw_umid" {
  name                = "${var.aca_name}-appgw-umid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.aca_name}-appgw-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.aca_name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_umid.id]
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  ssl_certificate {
    name                = "frontend-certificate"
    key_vault_secret_id = var.key_vault_appgw_certificate_secret_uri
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = var.custom_domain
    require_sni                    = true
    ssl_certificate_name           = "frontend-certificate"
  }

  backend_address_pool {
    name  = "aca-backend"
    fqdns = [azurerm_container_app.aca.ingress[0].fqdn]
  }

  backend_http_settings {
    name                                = "aca-https"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    pick_host_name_from_backend_address = true
    request_timeout                     = 30
    probe_name                          = "aca-health"
  }

  probe {
    name                                      = "aca-health"
    protocol                                  = "Https"
    path                                      = "/"
    pick_host_name_from_backend_http_settings = true
    interval                                  = 30
    timeout                                   = 10
    unhealthy_threshold                       = 3

    match {
      status_code = ["200-499"]
    }
  }

  rewrite_rule_set {
    name = "easy-auth-forwarded-headers"

    rewrite_rule {
      name          = "set-public-origin"
      rule_sequence = 100

      request_header_configuration {
        header_name  = "X-Forwarded-Host"
        header_value = var.custom_domain
      }

      request_header_configuration {
        header_name  = "X-Forwarded-Proto"
        header_value = "https"
      }
    }
  }

  request_routing_rule {
    name                       = "https-to-aca"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "aca-backend"
    backend_http_settings_name = "aca-https"
    rewrite_rule_set_name      = "easy-auth-forwarded-headers"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.appgw,
    azurerm_network_security_rule.appgw_gateway_manager,
    azurerm_network_security_rule.appgw_https,
    azurerm_role_assignment.appgw_certificate_reader,
    azurerm_private_dns_a_record.aca_wildcard,
    azurerm_private_dns_a_record.aca_apex,
    azurerm_private_dns_zone_virtual_network_link.aca,
    azapi_resource.easy_auth,
  ]
}

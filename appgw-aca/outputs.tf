output "easy_auth_client_id" {
  value = azuread_application.easy_auth_app_reg.client_id
}

output "easy_auth_redirect_uri" {
  value = "https://${var.custom_domain}/.auth/login/aad/callback"
}

output "aca_fqdn" {
  value = azurerm_container_app.aca.ingress[0].fqdn
}

output "aca_environment_private_ip" {
  value = azurerm_container_app_environment.cae.static_ip_address
}

output "aca_identity_principal_id" {
  value = azurerm_user_assigned_identity.aca_umid.principal_id
}

output "appgw_identity_principal_id" {
  value = azurerm_user_assigned_identity.appgw_umid.principal_id
}

output "public_dns_name_servers" {
  description = "Nameservers of the existing public DNS zone; registrar delegation should already point here."
  value       = data.azurerm_dns_zone.public.name_servers
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "application_url" {
  value = "https://${var.custom_domain}"
}
output "dns_server_private_ip" {
  description = "Private IP used as the spoke VNet's custom DNS server."
  value       = azurerm_network_interface.dns.private_ip_address
}

output "dns_server_public_ip" {
  description = "Public IP used to connect to the Windows DNS VM."
  value       = azurerm_public_ip.dns.ip_address
}

output "dns_vm_admin_username" {
  description = "Administrator username for the Windows DNS VM."
  value       = var.dns_vm_admin_username
}

output "dns_vm_admin_password" {
  description = "Generated administrator password for the Windows DNS VM."
  value       = random_password.dns_vm.result
  sensitive   = true
}

output "integrated_web_app_hostname" {
  description = "Default hostname of the VNet-integrated Linux Web App."
  value       = azurerm_linux_web_app.integrated.default_hostname
}

output "private_web_app_hostname" {
  description = "Default hostname of the private-endpoint Linux Web App."
  value       = azurerm_linux_web_app.private.default_hostname
}

output "private_endpoint_ip" {
  description = "Private IP allocated to the private Web App endpoint."
  value       = azurerm_private_endpoint.private_web_app.private_service_connection[0].private_ip_address
}
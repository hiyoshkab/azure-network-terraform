variable "resource_group_name" {
  type        = string
  description = "RG name"
  default     = "appgw-aca-rg"
}

variable "location" {
  type        = string
  description = "Region for RG"
  default     = "japaneast"
}

variable "vnet_name" {
  type        = string
  description = "VNET name"
  default     = "appgw-aca-vnet"
}

variable "appgw_network_security_group_name" {
  type        = string
  description = "Name of the NSG Terraform creates and attaches to the Application Gateway subnet in resource_group_name."
}

variable "cae_name" {
  type        = string
  description = "CAE name"
  default     = "cae-appgw-aca"
}

variable "aca_name" {
  type        = string
  description = "ACA name"
  default     = "nginx"
}

variable "custom_domain" {
  type        = string
  description = "This assumes you already have a custom domain"
}

variable "public_dns_zone_name" {
  type        = string
  description = "Existing public DNS zone to use, such as example.com. Use a lowercase domain without a trailing dot. Terraform manages only the gateway A record."

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.public_dns_zone_name))
    error_message = "Use a lowercase DNS zone name such as example.com, without a scheme, path, or trailing dot."
  }
}

variable "public_dns_zone_resource_group_name" {
  type        = string
  description = "Resource group containing the existing, delegated public DNS zone."
}

variable "tenant_id" {
  type        = string
  description = "This is your AAD Tenant ID"
}

variable "key_vault" {
  description = "Existing Key Vault to use."
  type = object({
    name                = string
    resource_group_name = string
  })
}

variable "key_vault_easyauth_secret_uri" {
  type        = string
  description = "URI of the Key Vault secret used by Easy Auth"

  validation {
    condition     = can(regex("^https://[^/]+/secrets/[a-zA-Z0-9-]+$", var.key_vault_easyauth_secret_uri))
    error_message = "Use a versionless Key Vault secret URI: https://<vault-host>/secrets/<secret-name>."
  }

}

variable "key_vault_appgw_certificate_secret_uri" {
  type        = string
  description = "URI of the Key Vault secret used by Application Gateway Certificate. Use 'secret' not 'certificate'"

  validation {
    condition     = can(regex("^https://[^/]+/secrets/[a-zA-Z0-9-]+$", var.key_vault_appgw_certificate_secret_uri))
    error_message = "Use a versionless Key Vault secret URI: https://<vault-host>/secrets/<certificate-name>."
  }
}
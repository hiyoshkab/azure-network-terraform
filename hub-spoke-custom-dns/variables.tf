variable "resource_group_name" {
  description = "Name of the resource group that contains the topology."
  type        = string
  default     = "hub-spoke-custom-dns-rg"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "centralus"
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network."
  type        = string
  default     = "vnet-hub-dns"
}

variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network."
  type        = string
  default     = "vnet-spoke"
}

variable "dns_vm_name" {
  description = "Name of the Windows Server DNS forwarder VM."
  type        = string
  default     = "vm-hub-dns"
}

variable "dns_vm_admin_username" {
  description = "Administrator username for the DNS VM."
  type        = string
  default     = "azureadmin"
}

variable "dns_vm_private_ip" {
  description = "Static private IPv4 address assigned to the DNS VM in the hub DNS subnet."
  type        = string
  default     = "10.0.0.4"

  validation {
    condition     = can(cidrhost("${var.dns_vm_private_ip}/32", 0))
    error_message = "dns_vm_private_ip must be a valid IPv4 address."
  }
}

variable "dns_vm_size" {
  description = "Azure VM size for the DNS forwarder."
  type        = string
  default     = "Standard_D2s_v4"
}

variable "dns_vm_rdp_source_cidr" {
  description = "Public IPv4 CIDR allowed to connect to the DNS VM over RDP. Restrict this to a trusted management address."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrnetmask(var.dns_vm_rdp_source_cidr))
    error_message = "dns_vm_rdp_source_cidr must be a valid IPv4 CIDR block."
  }
}

variable "app_service_plan_sku" {
  description = "SKU for the Linux App Service plan."
  type        = string
  default     = "P0v3"
}
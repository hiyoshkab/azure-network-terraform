variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "hub-spoke-demo-rg"
}

variable "location" {
  description = "Location of resource regions"
  type        = string
  default     = "centralus"
}

variable "vnet_spoke1" {
  description = "The name of the spoke 1 virtual network"
  type        = string
  default     = "vnet-spoke1"
}

variable "vnet_spoke2" {
  description = "The name of the spoke 2 virtual network"
  type        = string
  default     = "vnet-spoke2"
}

variable "vnet_hub" {
  description = "The name of the hub virtual network"
  type        = string
  default     = "vnet-hub"
}
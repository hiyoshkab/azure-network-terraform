resource "azurerm_public_ip" "dns" {
  name                = "pip-${var.dns_vm_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [ip_tags]
  }
}

resource "azurerm_network_interface" "dns" {
  name                = "nic-${var.dns_vm_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dns.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dns_vm_private_ip
    public_ip_address_id          = azurerm_public_ip.dns.id
  }
}

resource "random_password" "dns_vm" {
  length           = 24
  special          = true
  override_special = "!@#%"
}

resource "azurerm_windows_virtual_machine" "dns" {
  name                = var.dns_vm_name
  computer_name       = "hubdns01"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.dns_vm_size
  admin_username      = var.dns_vm_admin_username
  admin_password      = random_password.dns_vm.result
  network_interface_ids = [
    azurerm_network_interface.dns.id
  ]

  provision_vm_agent                                     = true
  secure_boot_enabled                                    = true
  vtpm_enabled                                           = true
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = false

  os_disk {
    name                 = "osdisk-${var.dns_vm_name}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}
}

resource "azurerm_virtual_machine_extension" "configure_dns" {
  name                       = "configure-dns-forwarder"
  virtual_machine_id         = azurerm_windows_virtual_machine.dns.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell.exe -NoLogo -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(file("${path.module}/scripts/configure-dns.ps1"), "UTF-16LE")}"
  })
}
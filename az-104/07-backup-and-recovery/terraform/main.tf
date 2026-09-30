resource "azurerm_resource_group" "backup" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "AZ104-Backup-Lab"
  }
}

resource "azurerm_virtual_network" "backup" {
  name                = "vnet-backup-tf-dev"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  tags = {
    Environment = var.environment
    Project     = "AZ104-Backup-Lab"
  }
}

resource "azurerm_subnet" "backup" {
  name                 = "snet-backup-tf-dev"
  resource_group_name  = azurerm_resource_group.backup.name
  virtual_network_name = azurerm_virtual_network.backup.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_network_interface" "backup" {
  name                = "nic-backup-tf-dev"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backup.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
    Project     = "AZ104-Backup-Lab"
  }
}

resource "azurerm_linux_virtual_machine" "backup" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.backup.name
  location            = azurerm_resource_group.backup.location
  size                = "Standard_D2als_v7"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.backup.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
    Project     = "AZ104-Backup-Lab"
  }
}

resource "azurerm_recovery_services_vault" "backup" {
  name                = var.vault_name
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant"

  tags = {
    Environment = var.environment
    Project     = "AZ104-Backup-Lab"
  }
}

resource "azurerm_backup_policy_vm" "backup" {
  name                = var.backup_policy_name
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.backup.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "22:00"
  }

  retention_daily {
    count = 7
  }

  instant_restore_retention_days = 2
}

resource "azurerm_backup_protected_vm" "backup" {
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.backup.name
  source_vm_id        = azurerm_linux_virtual_machine.backup.id
  backup_policy_id    = azurerm_backup_policy_vm.backup.id
}

# ============================================================
# EXISTING RESOURCE GROUP
# ============================================================
#
# Resource Group već postoji.
# Ovaj Terraform ga samo čita i koristi kao dependency.
#
data "azurerm_resource_group" "app_dev" {
  name = "rg-app-dev"
}


# ============================================================
# LOCATION
# ============================================================
#
# Centralno definiramo regiju za Compute resurse.
# Ako kasnije želiš promijeniti regiju, mijenjaš samo ovu vrijednost.
#
locals {
  location = "North Europe"
}


# ============================================================
# VIRTUAL NETWORK
# ============================================================
#
# Kreiramo privatnu Azure mrežu za Compute lab.
#
resource "azurerm_virtual_network" "compute" {
  name                = "vnet-compute-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name
  address_space       = ["10.20.0.0/16"]

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}


# ============================================================
# SUBNET
# ============================================================
#
# Kreiramo subnet unutar vnet-compute-dev.
#
# VNet:
# 10.20.0.0/16
#
# Subnet:
# 10.20.1.0/24
#
resource "azurerm_subnet" "compute" {
  name                 = "snet-compute-dev"
  resource_group_name  = data.azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.compute.name
  address_prefixes     = ["10.20.1.0/24"]
}


# ============================================================
# PUBLIC IP
# ============================================================
#
# Public IP ćemo povezati s NIC-em VM-a.
# Omogućuje nam SSH pristup s interneta.
#
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-app-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}


# ============================================================
# NETWORK SECURITY GROUP
# ============================================================
#
# NSG kontrolira mrežni promet.
#
# Za ovaj lab dopuštamo inbound SSH na TCP port 22.
#
# source_address_prefix = "*"
# znači da SSH dopuštamo s bilo koje IP adrese.
#
# To je prihvatljivo za privremeni lab,
# ali nije dobra production praksa.
#
resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-app-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  security_rule {
    name      = "Allow-SSH"
    priority  = 100
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "22"

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}


# ============================================================
# NETWORK INTERFACE
# ============================================================
#
# NIC je mrežna kartica VM-a.
#
# NIC:
# - nalazi se u našem subnetu
# - dobiva private IP iz subnet address rangea
# - koristi Public IP koji smo kreirali iznad
#
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-app-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  ip_configuration {
    name = "internal"

    subnet_id = azurerm_subnet.compute.id

    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.vm.id
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}


# ============================================================
# NSG <-> NIC ASSOCIATION
# ============================================================
#
# NSG postoji kao zaseban Azure resource.
# NIC postoji kao zaseban Azure resource.
#
# Ovim blokom ih povezujemo.
#
resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}


# ============================================================
# LINUX VIRTUAL MACHINE
# ============================================================
#
# Kreiramo Ubuntu Linux VM.
#
# VM koristi NIC koji smo definirali iznad.
# Preko NIC-a dobiva:
#
# - private IP
# - public IP
# - pristup subnetu/VNetu
# - NSG pravila
#
resource "azurerm_linux_virtual_machine" "app" {
  name                = "vm-app-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  size           = "Standard_B1s"
  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  # Koristimo postojeći public SSH key iz WSL-a.
  #
  # PRIVATE key ~/.ssh/id_rsa ostaje samo lokalno.
  #
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # OS Managed Disk.
  #
  # Na njemu se nalazi Ubuntu.
  #
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu image iz Azure Marketplacea.
  #
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

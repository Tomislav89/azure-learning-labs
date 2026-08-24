data "azurerm_resource_group" "app_dev" {
  name = "rg-app-dev"
}

resource "azurerm_storage_account" "storage" {
  name                            = "staz104storage1212"
  resource_group_name             = data.azurerm_resource_group.app_dev.name
  location                        = "North Europe"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
    CostCenter  = "LAB"
    ManagedBy   = "Portal"
  }
}

resource "azurerm_storage_container" "documents" {
  name                  = "az104-documents"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "files" {
  name               = "az104-share"
  storage_account_id = azurerm_storage_account.storage.id
  quota              = 5
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "move-old-blobs-to-cool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

data "azurerm_virtual_network" "app_dev" {
  name                = "vnet-app-dev"
  resource_group_name = data.azurerm_resource_group.app_dev.name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  virtual_network_name = data.azurerm_virtual_network.app_dev.name
  resource_group_name  = data.azurerm_resource_group.app_dev.name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.app_dev.name
  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "ha27ui25tw6r6"
  resource_group_name   = data.azurerm_resource_group.app_dev.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = data.azurerm_virtual_network.app_dev.id

  registration_enabled = false

  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob-dev"
  location            = "North Europe"
  resource_group_name = data.azurerm_resource_group.app_dev.name
  subnet_id           = data.azurerm_subnet.private_endpoints.id

  custom_network_interface_name = "pe-storage-blob-dev-nic"

  private_service_connection {
    name                           = "pe-storage-blob-dev"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = {
    Environment = "DEV"
  }
}

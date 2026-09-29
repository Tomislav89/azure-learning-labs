data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-monitor-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = {
    Environment = "DEV"
  }

}

resource "azurerm_virtual_network" "monitoring" {
  name                = "vnet-monitor-terraform-dev"
  address_space       = ["10.70.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "DEV"
  }

}

resource "azurerm_subnet" "monitoring" {
  name                 = "snet-monitor"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.monitoring.name
  address_prefixes     = ["10.70.1.0/24"]
}

resource "azurerm_public_ip" "monitoring" {
  name                = "pip-monitor-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "DEV"
  }

}

resource "azurerm_network_interface" "monitoring" {
  name                = "nic-monitor-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.monitoring.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.monitoring.id
  }

  tags = {
    Environment = "DEV"
  }

}

resource "azurerm_network_security_group" "monitoring" {
  name                = "nsg-monitor-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_subnet_network_security_group_association" "monitoring" {
  subnet_id                 = azurerm_subnet.monitoring.id
  network_security_group_id = azurerm_network_security_group.monitoring.id
}

resource "azurerm_linux_virtual_machine" "monitoring" {
  name                = "vm-monitor-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = "Standard_D2als_v7"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.monitoring.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type = "SystemAssigned"
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
    Environment = "DEV"
  }
}

resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.monitoring.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true

  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "dcr-linux-syslog-terraform-dev"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "log-analytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["log-analytics"]
  }

  data_sources {
    syslog {
      name           = "linux-syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["*"]
      log_levels = [
        "Debug",
        "Info",
        "Notice",
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency"
      ]
    }
  }

  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_monitor_data_collection_rule_association" "syslog" {
  name                    = "dcra-linux-syslog-terraform-dev"
  target_resource_id      = azurerm_linux_virtual_machine.monitoring.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog.id
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "diag-nsg-to-law"
  target_resource_id         = azurerm_network_security_group.monitoring.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-to-law-terraform"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-monitor-terraform-dev"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = "mon-tf"

  email_receiver {
    name                    = "email-alert"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = {
    Environment = "DEV"
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu-terraform-dev"
  resource_group_name = data.azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.monitoring.id]

  description = "Alert when average CPU usage exceeds 50 percent."
  severity    = 2
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 50
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "DEV"
  }
}

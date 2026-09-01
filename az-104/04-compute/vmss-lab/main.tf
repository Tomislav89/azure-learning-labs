data "azurerm_resource_group" "app_dev" {
  name = "rg-app-dev"
}

locals {
  location = "East US"
}

resource "azurerm_virtual_network" "vmss" {
  name                = "vnet-vmss-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name
  address_space       = ["10.30.0.0/16"]

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

resource "azurerm_subnet" "vmss" {
  name                 = "snet-vmss-dev"
  resource_group_name  = data.azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.vmss.name
  address_prefixes     = ["10.30.1.0/24"]
}

resource "azurerm_public_ip" "lb" {
  name                = "pip-vmss-eastus-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

resource "azurerm_lb" "vmss" {
  name                = "lb-vmss-eastus-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

resource "azurerm_lb_backend_address_pool" "vmss" {
  name            = "backend-vmss"
  loadbalancer_id = azurerm_lb.vmss.id
}

resource "azurerm_lb_probe" "vmss" {
  name            = "http-health-probe"
  loadbalancer_id = azurerm_lb.vmss.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.vmss.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss.id]
  probe_id                       = azurerm_lb_probe.vmss.id
}

resource "azurerm_linux_virtual_machine_scale_set" "app" {
  name                = "vmss-app-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  sku       = "Standard_D2als_v7"
  instances = 2

  admin_username = "azureuser"

  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx

    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
      - echo "<h1>Hello from Azure VMSS</h1>" > /var/www/html/index.html
  EOF
  )

  zones = ["1", "2"]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-vmss-app"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.vmss.id
      ]
    }
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_network_security_group" "vmss" {
  name                = "nsg-vmss-eastus-dev"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.app_dev.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-LB-Probe"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

resource "azurerm_subnet_network_security_group_association" "vmss" {
  subnet_id                 = azurerm_subnet.vmss.id
  network_security_group_id = azurerm_network_security_group.vmss.id
}

resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "autoscale-vmss-app-dev"
  resource_group_name = data.azurerm_resource_group.app_dev.name
  location            = local.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.app.id

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 2
      maximum = 4
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
  }
}

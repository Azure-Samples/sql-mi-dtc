resource "random_string" "bookings-app-password" {
  length           = 16
  special          = true
  upper            = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "azurerm_windows_virtual_machine_scale_set" "bookings-app" {
  name                 = "bookings-app"
  resource_group_name  = data.azurerm_resource_group.bookings-app.name
  location             = data.azurerm_resource_group.bookings-app.location
  computer_name_prefix = "app"
  sku                  = "Standard_D4s_v5"
  instances            = 2
  admin_password       = "${random_string.bookings-app-password.result}"
  admin_username       = "bookings-app"
  license_type         = "Windows_Server" 
  zones                = [1, 2, 3]
  upgrade_mode         = "Rolling"

  custom_data = base64encode(templatefile("config/connectionStrings.config.tpl", { database_fqdn = "${var.sqlmi-hostname}", database_user = "${var.sqlmi-username}", database_password = "${var.sqlmi-password}" }))

  source_image_id = var.vmss-image-id

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT0S"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = data.azurerm_subnet.app.id
      application_gateway_backend_address_pool_ids = [ for pool in azurerm_application_gateway.frontend.backend_address_pool : pool.id if pool.name == "addressPoolDefault" ]
    }
  }

  extension {
    name                 = "HealthExtension"
    publisher            = "Microsoft.ManagedServices"
    type                 = "ApplicationHealthWindows"
    type_handler_version = "1.0"
    settings             = jsonencode({
        "protocol"          = "HTTP"
        "port"              = "80"
        "requestPath"       = "/trip/create"
        "intervalInSeconds" = "15"
        "numberOfProbes"    = 3
  })
  }

  extension {
    name                 = "custom-data"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    protected_settings   = jsonencode({
        "commandToExecute" = "powershell -Command \"Copy-Item C:\\AzureData\\CustomData.bin -Destination C:\\InetPub\\wwwroot\\config\\connectionStrings.config\""
    })
  }

  lifecycle {
    ignore_changes = [ source_image_id ]
  }

}

resource "azurerm_monitor_autoscale_setting" "bookings-app" {
  name                = "AutoScaling"
  resource_group_name  = data.azurerm_resource_group.bookings-app.name
  location             = data.azurerm_resource_group.bookings-app.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.bookings-app.id

  profile {
    name = "AutoScaling"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.bookings-app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.bookings-app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

}
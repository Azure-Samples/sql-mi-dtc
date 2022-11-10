resource "random_string" "storage_account" {
  length           = 4
  special          = false
  upper            = false
}

resource "azurerm_storage_account" "bookingsapp" {
  name                     = "bookingsapp${random_string.storage_account.result}"
  resource_group_name      = data.azurerm_resource_group.bookings-app.name
  location                 = data.azurerm_resource_group.bookings-app.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
}

resource "azurerm_storage_container" "bookingsapp" {
  name                  = "bookingsapp"
  storage_account_name  = azurerm_storage_account.bookingsapp.name
  container_access_type = "private"
}
resource "azurerm_private_dns_zone" "bookings-app" {
  name                = "bookings-app.private"
  resource_group_name = data.azurerm_resource_group.bookings-app.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dtc-network" {
  name                  = "dtc-network"
  resource_group_name   = data.azurerm_resource_group.bookings-app.name
  private_dns_zone_name = azurerm_private_dns_zone.bookings-app.name
  virtual_network_id    = data.azurerm_virtual_network.bookings-app.id
  registration_enabled  = true
}
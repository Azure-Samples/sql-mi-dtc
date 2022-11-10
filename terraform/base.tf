provider "azurerm" {
  features {}
}

variable "sqlmi-hostname" {
  type    = string
}

variable "sqlmi-username" {
  type    = string
}

variable "sqlmi-password" {
  type    = string
}

variable "bookings-app-rg" {
  type    = string
  default = "bookings-app"
}

variable "bookings-app-network" {
  type    = string
  default = "dtc-network"
}

variable "bookings-app-subnet" {
  type    = string
  default = "apps"
}

variable "bookings-appgw-subnet" {
  type    = string
  default = "appgw"
}

variable "bookings-app-network-rg" {
  type    = string
  default = "bookings-app"
}

variable "vmss-image-id" {
  type    = string
}

data "azurerm_resource_group" "bookings-app" {
  name = var.bookings-app-rg
}

data "azurerm_virtual_network" "bookings-app" {
  name                = var.bookings-app-network
  resource_group_name = var.bookings-app-network-rg
}

data "azurerm_subnet" "app" {
  name                 = var.bookings-app-subnet
  virtual_network_name = var.bookings-app-network
  resource_group_name  = var.bookings-app-network-rg
}

data "azurerm_subnet" "appgw" {
  name                 = var.bookings-appgw-subnet
  virtual_network_name = var.bookings-app-network
  resource_group_name  = var.bookings-app-network-rg
}

output "storage_account" {
  value       = azurerm_storage_account.bookingsapp.name
  description = "Storage Account"
}

output "application_url" {
  value       = "http://${azurerm_public_ip.frontend-appgw.ip_address}/trip/create"
  description = "Application URL"
}


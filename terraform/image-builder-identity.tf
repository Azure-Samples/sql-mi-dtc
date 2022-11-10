data "azurerm_subscription" "current" {
}

resource "azurerm_role_definition" "image_builder_role" {
  name        = "Azure Image Builder Service Image Creation Role"
  scope       = data.azurerm_subscription.current.id
  description = "Image Builder access to create resources for the image build."

  permissions {
    actions     = [ "Microsoft.Compute/galleries/read",
                    "Microsoft.Compute/galleries/images/read",
                    "Microsoft.Compute/galleries/images/versions/read",
                    "Microsoft.Compute/galleries/images/versions/write",
                    "Microsoft.Compute/images/write",
                    "Microsoft.Compute/images/read",
                    "Microsoft.Compute/images/delete",
                    "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action" ]
    not_actions = []
  }

}

resource "azurerm_user_assigned_identity" "image_builder" {
  resource_group_name = data.azurerm_resource_group.bookings-app.name
  location            = data.azurerm_resource_group.bookings-app.location

  name = "image-builder"
}

resource "azurerm_role_assignment" "image_builder_rg" {
  scope                = data.azurerm_resource_group.bookings-app.id
  role_definition_name = azurerm_role_definition.image_builder_role.name
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}

resource "azurerm_role_assignment" "image_builder_container" {
  scope                = azurerm_storage_container.bookingsapp.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}

resource "azurerm_role_assignment" "image_builder_storage" {
  scope                = azurerm_storage_account.bookingsapp.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}
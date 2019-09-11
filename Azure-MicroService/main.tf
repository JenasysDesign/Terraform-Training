provider "azurerm" {
  version = "=1.28.0"
  subscription_id = var.azSubscriptionId
  tenant_id       = var.azTenantId
}

# Resource Group to store all the related objects.
resource "azurerm_resource_group" "envgrp" {  
  name      = join("-", [var.Env, "rg"] )
  location  = var.azLocation
  tags      = var.azDefaultDevTags
}

# Queue services for Producer/Consumer software pattern.
resource "azurerm_servicebus_namespace" "queue" {
  name                = join("-", [ var.Env, "sbus" ] )
  resource_group_name = azurerm_resource_group.envgrp.name
  location            = azurerm_resource_group.envgrp.location
  sku                 = "Standard"
  tags                = var.azDefaultDevTags
}

resource "azurerm_servicebus_namespace_authorization_rule" "queuesecurity" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_servicebus_namespace.queue.name
  resource_group_name = azurerm_resource_group.envgrp.name

  listen = true
  send   = true
  manage = true
}

# Storeage account (LowerCaseOnly)
resource "azurerm_storage_account" "storage" {
  name                     = lower(join( var.Env, "storage" ))
  resource_group_name      = azurerm_resource_group.envgrp.name
  location                 = azurerm_resource_group.envgrp.location
  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  enable_https_traffic_only = true
  tags                     = var.azDefaultDevTags
}

# Create Storage and share for portal.azure.com Shell commands (Powershell/Bash)
resource "azurerm_storage_account" "shellstorage" {
  name                     = lower(join( "shell", "storage" ))
  resource_group_name      = azurerm_resource_group.envgrp.name
  location                 = "Southeast Asia"
  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  tags                     = merge({ ms-resource-usage = "azure-cloud-shell" }, var.azDefaultDevTags)
}

# Exposing a share required for portal.azure.com Shell commands (Powershell/Bash)
# TODO - Unsure of the security implications of this
resource "azurerm_storage_share" "shellShare" {
  name                 = "powershell"
  storage_account_name = azurerm_storage_account.shellstorage.name
  resource_group_name  = azurerm_resource_group.envgrp.name
  quota                = 2
}
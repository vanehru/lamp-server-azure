terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" { features {} }

resource "azurerm_storage_account" "sa" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  enable_https_traffic_only       = true
  is_hns_enabled                  = true
  is_sftp_enabled                 = true
  local_user_enabled              = true
  allow_nested_items_to_be_public = false
  allow_blob_public_access        = false

  # Lock to private-only if requested
  public_network_access_enabled = var.private_only ? false : true
  shared_access_key_enabled     = true
  allow_shared_key_access       = false # harden; use managed identity or SAS rather than account keys

  blob_properties {
    versioning_enabled = true
  }

  lifecycle {
    ignore_changes = [
      shared_access_key_enabled
    ]
  }
}

# Blob containers
resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.containers)
  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Optional SFTP local user + SSH keys
resource "azurerm_storage_account_local_user" "sftp_user" {
  count                = var.sftp_local_user_name != null ? 1 : 0
  name                 = var.sftp_local_user_name
  storage_account_id   = azurerm_storage_account.sa.id
  home_directory       = var.sftp_home_directory
  ssh_password_enabled = false
  ssh_key_enabled      = true

  permission_scope {
    service       = "blob"
    resource_name = var.sftp_home_directory
    permissions   = var.sftp_permissions
  }

  dynamic "ssh_authorized_key" {
    for_each = var.ssh_public_keys
    content {
      key         = ssh_authorized_key.value
      description = "sftp-key"
    }
  }
}

# Private DNS zone for blob
resource "azurerm_private_dns_zone" "blob" {
  count               = var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  count                 = var.create_private_dns_zone ? 1 : 0
  name                  = "blob-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# Private Endpoint for blob subresource
resource "azurerm_private_endpoint" "pe_blob" {
  name                = "${var.name}-pe-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "blob-conn"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_dns_zone_group" "blob_zone_group" {
  count               = var.create_private_dns_zone ? 1 : 0
  name                = "blob-dns-group"
  private_endpoint_id = azurerm_private_endpoint.pe_blob.id

  private_dns_zone_configs {
    name                = "blob-zone-config"
    private_dns_zone_id = azurerm_private_dns_zone.blob[0].id
  }
}
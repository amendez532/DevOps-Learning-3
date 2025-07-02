terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "822b42b7-8868-4c34-bcde-4b8f525bbe89"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_storage_account" "logs_sa" {
  name                     = "logs${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "log_container" {
  name                  = "applogs"
  storage_account_id    = azurerm_storage_account.logs_sa.id
  container_access_type = "private"
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.enable_purge_protection
  soft_delete_retention_days = 7
  tags                       = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.logs_sa.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "logs-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_container_group" "app" {
  name                = "aci-${var.app_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "${var.app_name}-${random_string.suffix.result}"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = var.acr_sp_client_id
    password = var.acr_sp_client_secret
  }

  container {
    name   = var.app_name
    image  = "${azurerm_container_registry.acr.login_server}/${var.docker_image}:${var.docker_image_tag}"
    cpu    = var.container_cpu
    memory = var.container_memory

    ports {
      port     = var.app_port
      protocol = "TCP"
    }

    volume {
      name       = "secrets"
      mount_path = "/mnt/secrets"
      secret = {
        "storage-key" = azurerm_key_vault_secret.storage_key.value
      }
    }

    environment_variables = {
      STORAGE_ACCOUNT = azurerm_storage_account.logs_sa.name
      CONTAINER_NAME  = azurerm_storage_container.log_container.name
    }
  }

  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.law.workspace_id
      workspace_key = azurerm_log_analytics_workspace.law.primary_shared_key
    }
  }
}

resource "azurerm_role_assignment" "aci_kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_group.app.identity[0].principal_id
}

resource "azurerm_role_assignment" "aci_storage" {
  scope                = azurerm_storage_account.logs_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_container_group.app.identity[0].principal_id
}

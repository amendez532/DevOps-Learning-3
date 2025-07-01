output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_fqdn" {
  value = azurerm_container_group.app.fqdn
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

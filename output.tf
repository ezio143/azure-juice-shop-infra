output "resource_group_name" {
  value = azurerm_resource_group.day2.name
}

output "app_name" {
  value = azurerm_linux_web_app.juice.name
}

output "app_url" {
  value = "https://${azurerm_linux_web_app.juice.default_hostname}"
}

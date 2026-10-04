
# using existing manually created RG
data "azurerm_resource_group" "main" {
  name = "rg-tfstate"
}

# resource "azurerm_resource_group" "main" {
#   name     = "rg-${var.prefix}-${random_string.suffix.result}"
#   location = var.location
#   tags     = var.tags
# }


resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}


resource "azurerm_service_plan" "main" {
  name                = "asp-${var.prefix}-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "juice" {
  name                = "app-${var.prefix}-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  https_only = true
  tags       = var.tags

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    http2_enabled       = true

    application_stack {
      docker_image_name   = "${var.docker_image}:${var.docker_tag}"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    WEBSITES_PORT                       = "3000" # Juice Shop listens on 3000
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}
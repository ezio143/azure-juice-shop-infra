locals {
  tags = {
    project = "azure-security-study"
    day     = "2"
    purpose = "appsec-devsecops-waf"
    managed = "terraform"
  }
}

# Web app names are globally unique, so add a random suffix.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "day2" {
  name     = "rg-${var.name_prefix}-appsec"
  location = var.location
  tags     = local.tags
}

resource "azurerm_service_plan" "app-service-plan" {
  name                = "asp-${var.name_prefix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.day2.name
  location            = azurerm_resource_group.day2.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = local.tags
}

resource "azurerm_linux_web_app" "juice" {
  name                = "app-juice-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.day2.name
  location            = azurerm_resource_group.day2.location
  service_plan_id     = azurerm_service_plan.app-service-plan.id
  https_only          = true
  tags                = local.tags

  site_config {
    # Always On is not allowed on F1/D1.
    always_on           = !contains(["F1", "D1"], var.sku_name)
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    http2_enabled       = true

    application_stack {
      docker_image_name   = var.juice_shop_image
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    # Juice Shop listens on 3000 inside the container.
    WEBSITES_PORT                       = "3000"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    # First boot of Juice Shop can be slow on a free plan.
    WEBSITES_CONTAINER_START_TIME_LIMIT = "600"
  }
}

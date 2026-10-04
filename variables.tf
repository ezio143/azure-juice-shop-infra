
variable "location" {
  type    = string
  default = "centralindia"
}

variable "prefix" {
  type    = string
  default = "juiceshop"
}

variable "docker_image" {
  description = "Docker Hub repository, e.g. youruser/juice-shop"
  type        = string
  default     = "bkimminich/juice-shop"
}

variable "docker_tag" {
  description = "Image tag. Step 6 will set this to the commit SHA."
  type        = string
  default     = "latest"
}

variable "sku_name" {
  description = "App Service plan SKU. B1 is the cheapest tier that runs Linux containers."
  type        = string
  default     = "B1"
}

variable "tags" {
  type = map(string)
  default = {
    project    = "devsecops-portfolio"
    managed_by = "terraform"
  }
}
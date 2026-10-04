variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "name_prefix" {
  type    = string
  default = "day2"
}

variable "sku_name" {
  type    = string
  default = "F1"

}

variable "juice_shop_image" {
  description = "Docker Hub image for juice shop"
  type        = string
  default     = "bkimminich/juice-shop:latest"
}
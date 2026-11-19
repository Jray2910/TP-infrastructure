variable "api_image" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  default = "eu-north-1"
}

variable "image_tag" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_allocated_storage" {
  default = 20
}

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
variable "app_keys" {}
variable "api_token_salt" {}
variable "admin_jwt_secret" {}
variable "transfer_token_salt" {}
variable "encryption_key" {}
variable "admin_auth_secret" {}

# variable "ecr_repo_url" {
#   description = "Full URL of the ECR repository"
#   type        = string
# }

variable "dockerhub_username" {}
variable "dockerhub_password" {}
variable "image_name" {
  default = "strapi-terraform"
}
variable "aws_region" {
  type    = string
  default = "eu-north-1"
}


variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Existing AWS key pair name for SSH (leave blank to skip)"
  default     = "strapi-key"
}

variable "ssh_private_key_path" {
  type = string
  description = "Path to private key for Terraform remote-exec (optional)"
  default = ""
}

variable "db_name" {
  type    = string
  default = "strapi_db"
}

variable "db_username" {
  type    = string
  default = "strapi_user"
}

variable "db_password" {
  type        = string
  description = "Postgres DB password (sensitive)"
  sensitive   = true
  default     = "strapi_pass"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
variable "image_tag" {
  type    = string
  default = "latest"
}

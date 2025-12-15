variable "aws_region" {
  default = "eu-north-1"
}

variable "image_tag" {
  description = "Docker image tag pushed to ECR"
  type        = string
}
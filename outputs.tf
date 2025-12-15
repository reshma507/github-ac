output "ecr_repository_url" {
  value = data.aws_ecr_repository.strapi.repository_url
}


output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

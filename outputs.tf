output "ecr_repository_url" {
  value = var.ecr_repo_url
}



output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "vpc_id" {
  description = "ID da VPC dedicada ao banco de dados."
  value       = aws_vpc.database.id
}

output "vpc_cidr_block" {
  description = "Bloco CIDR da VPC do banco de dados. Consumido por oficina-mecanica-infra-kubernetes para configurar o VPC Peering entre as duas VPCs."
  value       = aws_vpc.database.cidr_block
}

output "default_route_table_id" {
  description = "ID da route table padrão (única, já que esta VPC não tem Internet Gateway/NAT) da VPC do banco de dados. Usado por oficina-mecanica-infra-kubernetes para adicionar a rota de volta ao CIDR do EKS via VPC Peering."
  value       = aws_vpc.database.default_route_table_id
}

output "private_subnet_ids" {
  description = "Subnets privadas usadas pelo RDS."
  value       = aws_subnet.database[*].id
}

output "security_group_id" {
  description = "Security group do RDS."
  value       = aws_security_group.rds.id
}

output "rds_endpoint" {
  description = "Endpoint DNS do RDS PostgreSQL."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Porta do RDS PostgreSQL."
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nome do database PostgreSQL no RDS."
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Usuário PostgreSQL no RDS."
  value       = aws_db_instance.postgres.username
}

output "rds_secret_arn" {
  description = "ARN do secret do Secrets Manager com as credenciais do RDS."
  value       = aws_secretsmanager_secret.rds.arn
}

output "rds_password" {
  description = "Senha master do RDS. Sensível: use `terraform output -raw rds_password` para copiar para o secret POSTGRES_PASSWORD do repositório oficina-mecanica-fiap."
  value       = random_password.master.result
  sensitive   = true
}

variable "project_name" {
  description = "Nome lógico do projeto para tags e nomes de recursos."
  type        = string
  default     = "oficina-mecanica-fiap"
}

variable "environment" {
  description = "Identificador do ambiente AWS (dev, homologacao, producao)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC dedicada ao banco de dados. Fora do 10.0.0.0/16 usado pela VPC do EKS (repositório oficina-mecanica-infra-kubernetes) para não colidir quando forem peerados."
  type        = string
  default     = "10.90.0.0/24"
}

variable "allowed_cidr_blocks" {
  description = "Blocos CIDR autorizados a acessar o PostgreSQL na porta 5432. Vazio por padrão: preencha com o CIDR da VPC do EKS (ou configure VPC peering) quando o repositório oficina-mecanica-infra-kubernetes estiver implementado."
  type        = list(string)
  default     = []
}

variable "rds_instance_class" {
  description = "Classe da instância RDS PostgreSQL."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Armazenamento inicial do RDS, em GiB."
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Armazenamento máximo para autoscaling do RDS, em GiB."
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "Versão do PostgreSQL no RDS."
  type        = string
  default     = "16.3"
}

variable "rds_database_name" {
  description = "Nome do database PostgreSQL usado pela aplicação."
  type        = string
  default     = "oficina_mecanica"
}

variable "rds_username" {
  description = "Usuário master do PostgreSQL no RDS."
  type        = string
  default     = "oficina"
}

variable "rds_backup_retention_period" {
  description = "Retenção de backups automáticos do RDS, em dias."
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Protege a instância RDS contra deleção acidental."
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Pula snapshot final ao destruir o RDS. Use false em produção."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionais aplicadas aos recursos AWS."
  type        = map(string)
  default     = {}
}

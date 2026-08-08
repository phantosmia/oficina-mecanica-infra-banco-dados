# oficina-mecanica-infra-banco-dados

Infraestrutura como código (Terraform) do **Banco de Dados Gerenciado** do sistema de gestão de oficina mecânica — repositório 3 dos 4 exigidos pela Fase 3 do Tech Challenge (SOAT/FIAP).

Provisiona uma instância **Amazon RDS PostgreSQL** de forma autocontida: este repositório não depende do repositório de infraestrutura Kubernetes para existir, criando sua própria VPC dedicada ao banco.

## Tecnologias

- Terraform >= 1.6
- AWS RDS (PostgreSQL), VPC, Secrets Manager
- GitHub Actions

## O que é provisionado

- VPC dedicada (`10.90.0.0/24` por padrão), sem Internet Gateway/NAT — o RDS não precisa de saída para a internet.
- 2 subnets privadas em AZs distintas + `aws_db_subnet_group`.
- Security group liberando a porta 5432 a partir de `var.allowed_cidr_blocks`.
- Instância `aws_db_instance` PostgreSQL (gp3, criptografada, não publicamente acessível).
- Secret no AWS Secrets Manager (`<project>-<environment>/postgres`) com host, porta, nome do banco, usuário e senha.

## Por que uma VPC própria?

Para manter este repositório independente do repositório de infraestrutura Kubernetes (`oficina-mecanica-infra-kubernetes`) — nenhum dos dois precisa existir primeiro, nem depende do outro para ser aplicado — o banco vive em sua própria VPC. Agora que o repositório de Kubernetes está implementado, o caminho recomendado é popular `allowed_cidr_blocks` com o output `vpc_cidr_block` daquele repositório e, se necessário, configurar VPC Peering entre as duas VPCs para reduzir a exposição da porta 5432 — esse trabalho fica para uma etapa futura, quando também a automação da sincronização de outputs entre repositórios for implementada.

## Uso local

```bash
cp backend.hcl.example backend.hcl   # ajuste bucket/tabela (mesmo backend do oficina-mecanica-fiap)
cp terraform.tfvars.example terraform.tfvars

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

O backend remoto (S3 + DynamoDB) é o **mesmo** já criado por `infra/backend` no repositório `oficina-mecanica-fiap` — este repositório só usa uma `key` de state diferente (`database/<environment>/terraform.tfstate`), não cria um bucket/tabela novos.

## CI/CD

Workflow em [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml):

- **Pull Request**: `terraform fmt -check`, `validate` e `plan` (sem backend remoto — validação de sintaxe/config, não reflete um ambiente real).
- **Push para `homologacao` ou `producao`**: `init` (backend remoto, state `database/<branch>/terraform.tfstate`), `plan` e `apply` automático, autenticando via credenciais temporárias do AWS Academy Lab (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`).

### Regras de proteção

- Branch `main` protegida: sem commit direto, merge só via Pull Request.
- `homologacao` e `producao` disparam `apply` automático no push (ambientes GitHub `homologacao`/`producao`, o que permite configurar secrets/aprovações por ambiente).

### Secrets e variables necessários

| Tipo | Nome | Descrição |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | Access key temporária do AWS Academy Lab |
| Secret | `AWS_SECRET_ACCESS_KEY` | Secret key temporária do AWS Academy Lab |
| Secret | `AWS_SESSION_TOKEN` | Session token temporário do AWS Academy Lab |
| Secret | `TF_BACKEND_CONFIG` | Conteúdo completo de um `backend.hcl` (alternativa às variables abaixo) |
| Variable | `AWS_REGION` | Região AWS |
| Variable | `TF_STATE_BUCKET` | Bucket S3 do state (mesmo do `oficina-mecanica-fiap`) |
| Variable | `TF_LOCK_TABLE` | Tabela DynamoDB de lock (mesma do `oficina-mecanica-fiap`) |
| Variable | `TF_STATE_REGION` | Região do backend S3 |

## Integração com o repositório da aplicação (`oficina-mecanica-fiap`)

Depois de um `apply` bem-sucedido (local ou via CI em `homologacao`/`producao`), copie os outputs para o repositório `oficina-mecanica-fiap`:

| Output deste repositório | Onde colar no `oficina-mecanica-fiap` |
|---|---|
| `terraform output -raw rds_endpoint` | GitHub **variable** `RDS_ENDPOINT` |
| `terraform output -raw rds_secret_arn` | GitHub **variable** `RDS_SECRET_ARN` |
| `terraform output -raw rds_password` | GitHub **secret** `POSTGRES_PASSWORD` |

Essa sincronização é **manual** por enquanto — a automação via Terraform remote state entre os dois repositórios fica para uma etapa futura, quando o repositório de infraestrutura Kubernetes também tiver implementação real.

## Variáveis e outputs

Ver [`variables.tf`](variables.tf) e [`outputs.tf`](outputs.tf) para a lista completa, com descrições.

## Repositórios relacionados

- [oficina-mecanica-fiap](https://github.com/phantosmia/oficina-mecanica-fiap) — aplicação principal (consome este banco).
- [oficina-mecanica-infra-kubernetes](https://github.com/phantosmia/oficina-mecanica-infra-kubernetes) — infraestrutura do cluster EKS.
- [oficina-mecanica-lambda-auth](https://github.com/phantosmia/oficina-mecanica-lambda-auth) — function serverless de autenticação via CPF (placeholder).

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

Este repositório não lê o state de nenhum outro (é o primeiro da cadeia de apply: banco → cluster → aplicação — ver "Integração" abaixo), então o banco vive em sua própria VPC em vez de depender da VPC do repositório de infraestrutura Kubernetes (`oficina-mecanica-infra-kubernetes`) existir primeiro. O caminho recomendado para reduzir a exposição da porta 5432 é popular `allowed_cidr_blocks` com o output `vpc_cidr_block` daquele repositório e, se necessário, configurar VPC Peering entre as duas VPCs — isso fica deliberadamente manual (não automatizado via remote state), porque afeta regras de security group e é uma decisão de rede que vale revisar antes de aplicar, não um dado que deveria fluir sozinho a cada apply do outro repositório.

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

## Integração com os outros repositórios (via `terraform_remote_state`)

Este repositório, o `oficina-mecanica-infra-kubernetes` e o `oficina-mecanica-fiap` compartilham o mesmo backend S3 (criado por `infra/backend` no repositório `oficina-mecanica-fiap`). Isso permite que os outros dois leiam os outputs deste repositório **automaticamente**, sem copiar nada manualmente:

- `oficina-mecanica-infra-kubernetes` lê `rds_secret_arn` para autorizar o External Secrets Operator a ler esse secret.
- `oficina-mecanica-fiap` (`infra/aws`) lê `rds_endpoint` e `rds_password` para o secret e o ConfigMap da API.

Isso estabelece a ordem de apply da Fase 3: **este repositório primeiro**, depois `oficina-mecanica-infra-kubernetes`, depois `oficina-mecanica-fiap`. Se a `key` do state deste repositório no ambiente esperado (`database/<environment>/terraform.tfstate`) ainda não existir, o `plan`/`apply` dos outros dois falha com um erro de leitura do backend S3 — aplique este repositório primeiro nesse caso.

## Variáveis e outputs

Ver [`variables.tf`](variables.tf) e [`outputs.tf`](outputs.tf) para a lista completa, com descrições.

## Repositórios relacionados

- [oficina-mecanica-fiap](https://github.com/phantosmia/oficina-mecanica-fiap) — aplicação principal (consome este banco).
- [oficina-mecanica-infra-kubernetes](https://github.com/phantosmia/oficina-mecanica-infra-kubernetes) — infraestrutura do cluster EKS.
- [oficina-mecanica-lambda-auth](https://github.com/phantosmia/oficina-mecanica-lambda-auth) — function serverless de autenticação via CPF (placeholder).

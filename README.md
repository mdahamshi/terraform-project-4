# Terraform AWS RDS Module

A reusable Terraform module that automates the deployment of an Amazon RDS instance, with a strong focus on **security**, **modularity**, and **reusability**.

Built as part of the *Mastering Terraform: From Beginner to Expert* course.

## Table of Contents

- [Features](#features)
- [Repository Structure](#repository-structure)
- [Module Variables](#module-variables)
- [Variable Validations](#variable-validations)
- [Module Outputs](#module-outputs)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Verifying the Validations](#verifying-the-validations)
- [Cleanup](#cleanup)
- [Security Considerations](#security-considerations)

## Features

- **Standard module structure** — the module lives under `modules/rds` with dedicated `variables.tf`, `rds.tf`, `outputs.tf`, and `networking-validation.tf` files.
- **Comprehensive input validation** — every module input is validated at plan time, catching misconfigurations before anything is deployed.
- **Network validation with checkable postconditions** — subnets and security groups are inspected via data sources and validated using Terraform `postcondition` checks.
- **Custom VPC isolation** — RDS instances can only be deployed in private subnets of a non-default VPC.
- **Compliant & non-compliant test resources** — the root configuration ships with both compliant and non-compliant subnets and security groups, so you can prove the validation logic works.
- **Not publicly accessible** — the instance is created with `publicly_accessible = false`.

## Repository Structure

```
.
├── provider.tf                    # AWS provider configuration (eu-west-1)
├── networking.tf                  # Custom VPC, subnets, security groups & rules
├── rds.tf                         # Module call that deploys the RDS instance
├── outputs.tf                     # Root-level outputs (e.g. RDS endpoint)
└── modules/
    └── rds/                       # Reusable RDS module
        ├── variables.tf           # Module input variables + validations
        ├── rds.tf                 # aws_db_instance, db subnet & parameter groups
        ├── outputs.tf             # Module outputs (arn, id, endpoint, ...)
        ├── networking-validation.tf  # Subnet & SG postcondition validations
        └── provider.tf            # Required provider constraints
```

## Module Variables

| Variable            | Type     | Default            | Description                                          |
| ------------------- | -------- | ------------------ | ---------------------------------------------------- |
| `project_name`      | `string` | — (required)       | The project name. Used as the DB identifier prefix.  |
| `instance_class`    | `string` | `"db.t3.micro"`    | The RDS instance class.                              |
| `storage_size`      | `number` | `10`               | Allocated storage in GB.                             |
| `engine`            | `string` | `"postgres-latest"`| The database engine to deploy.                       |
| `credentials`       | `object` | — (required)       | `{ username, password }` used for DB authentication. |
| `subnet_ids`        | `list(string)` | — (required) | Subnet IDs where the RDS instance is deployed.       |
| `security_group_ids`| `list(string)` | — (required) | Security groups to attach to the RDS instance.       |

### Credentials Object

```hcl
credentials = {
  username = "db_admin"
  password = "12A3a332"
}
```

The `credentials` variable is marked `sensitive = true`, so Terraform never writes the password to state or plan output in plain text.

## Variable Validations

Every input is validated either through `validation` blocks on the variable or through data-source `postcondition` checks.

### In `variables.tf`

| Variable         | Validation                                                                  |
| ---------------- | --------------------------------------------------------------------------- |
| `instance_class` | Must be `db.t3.micro` (free-tier eligible).                                 |
| `storage_size`   | Must be greater than `5` and at most `10` GB (free-tier range).             |
| `engine`         | Must be `postgres-latest` or `postgres-14`.                                 |
| `credentials.password` | Must contain at least one letter and one digit, be at least 8 chars long, and use only `a-zA-Z0-9+_?-`. |

### In `networking-validation.tf` (postconditions)

| Input              | Validation                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------ |
| `subnet_ids`       | Each subnet must **not** belong to the default VPC.                                              |
| `subnet_ids`       | Each subnet must be marked as private via the `Access = "private"` tag.                          |
| `security_group_ids` | Inbound rules must **not** allow traffic from IP CIDR blocks; only references to other security groups are permitted. |

## Module Outputs

| Output                 | Description                                          |
| ---------------------- | ---------------------------------------------------- |
| `rds_instance_arn`     | The ARN of the created RDS instance.                 |
| `rds_instance_id`      | The ID of the created RDS instance.                  |
| `rds_instance_port`    | The port the DB is listening on.                     |
| `rds_instance_address` | The hostname of the created RDS instance.            |
| `rds_instance_endpoint`| Endpoint in `address:port` format.                   |

The root configuration exposes the instance endpoint via `outputs.tf`:

```hcl
output "rds_endpoint" {
  value = module.database.rds_instance_endpoint
}
```

## Prerequisites

- Terraform `~> 1.7`
- AWS Provider `~> 5.0`
- Valid AWS credentials configured for the `eu-west-1` region
- An AWS account that supports RDS free-tier limits (`db.t3.micro`, up to 10 GB storage)

## Usage

```hcl
module "database" {
  source = "./modules/rds"

  project_name = "project-04-rds-module"
  instance_class = "db.t3.micro"
  storage_size   = 10
  engine         = "postgres-latest"

  credentials = {
    username = "db_admin"
    password = "12A3a332"
  }

  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id,
  ]

  security_group_ids = [
    aws_security_group.compliant.id,
  ]
}
```

### Deploy

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

After a successful apply you will see the RDS endpoint in the outputs:

```text
rds_endpoint = "project-04-rds-module.xxxxxxxxxxxx.eu-west-1.rds.amazonaws.com:5432"
```

## Verifying the Validations

The root configuration in `networking.tf` defines both compliant and non-compliant resources so you can prove the validations fire:

- **Compliant subnet** — `aws_subnet.private1` / `aws_subnet.private2` (custom VPC, tagged `Access = "Private"`).
- **Non-compliant subnet** — `aws_subnet.not_allowed` (in the default VPC, not tagged private).
- **Compliant security group** — `aws_security_group.compliant` (inbound rule references another security group only).
- **Non-compliant security group** — `aws_security_group.non_compliant` (inbound rule opens `0.0.0.0/0`).

> Note: the non-compliant resources exist in the configuration for demonstration purposes and are intentionally **not** passed to the module. To verify a validation, temporarily pass a non-compliant value to the module and run `terraform plan` — the plan should fail with a descriptive `error_message`.

For example, passing the default-VPC subnet to the module:

```bash
terraform plan
```

produces something like:

```text
Error: Resource postcondition failed
| The following subnet is part of the default VPC:
| Name = subnet-default-vpc
| ID   = subnet-xxxx
| Please do not deploy RDS instances in the default VPC.
```

## Cleanup

To tear down all created resources (including the RDS instance and all supporting networking resources):

```bash
terraform destroy
```

This removes the VPC, subnets, security groups, DB subnet group, parameter group, and the RDS instance itself.

## Security Considerations

- The RDS instance is created with `publicly_accessible = false` — it is never exposed to the internet.
- Only private, non-default-VPC subnets can be used as deployment targets.
- Security groups must reference other security groups for inbound traffic — opening ports to IP CIDR blocks is blocked by validation.
- DB credentials are marked `sensitive`, keeping them out of state and console output.
- A final snapshot is skipped (`skip_final_snapshot = true`) to keep the project clean for learning purposes — consider enabling `final_snapshot_identifier` for production.

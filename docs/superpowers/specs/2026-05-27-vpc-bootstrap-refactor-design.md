# VPC Bootstrap Tool — Refactoring Design Spec

## Goal

Restructure the Terraform VPC project to follow Terraform conventions, replace the deprecated NAT AMI with fck-nat, and make the project portable for quick-bootstrapping a VPC in any AWS account.

## File Structure

```
/
├── main.tf           # terraform block, provider, backend config
├── variables.tf      # all inputs with types, descriptions, defaults, validation
├── vpc.tf            # VPC + IGW
├── subnets.tf        # all subnets via cidrsubnet()
├── routes.tf         # route tables + associations
├── nat.tf            # fck-nat instance (flattened from modules/natinstance/)
├── dns.tf            # optional private Route53 zone
├── endpoints.tf      # optional VPC endpoints
├── outputs.tf        # grouped outputs for downstream consumption
├── data.tf           # data sources (fck-nat AMI, caller identity)
└── backends/
    └── sg.tfbackend  # example backend config file
```

The `modules/natinstance/` directory is deleted. The `ssm.tf` file is deleted. All resources live in the root module.

## Variables

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `aws_region` | `string` | `"ap-southeast-1"` | Target region |
| `project_code` | `string` | `"vpcsg"` | Naming prefix for all resources |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR block; all subnets auto-derived |
| `availability_zones` | `list(string)` | `["ap-southeast-1a", "ap-southeast-1b"]` | AZs to deploy across |
| `environments` | `map(object({index = number, tiers = set(string)}))` | See below | Environments, CIDR index, and subnet tiers |
| `nat_instance_type` | `string` | `"t4g.nano"` | NAT instance size |
| `enable_nat_instance` | `bool` | `true` | Toggle NAT instance + app subnets |
| `enable_vpc_endpoints` | `bool` | `true` | Free endpoints: S3 + DynamoDB gateways + EC2 Instance Connect |
| `enable_private_dns` | `bool` | `true` | Private Route53 zone |

Default `environments`:
```hcl
{
  prd     = { index = 0, tiers = ["web", "app"] }
  preprod = { index = 1, tiers = ["web", "app"] }
  com     = { index = 2, tiers = ["web", "db"] }
}
```

## CIDR Allocation Strategy

Each environment gets a `/18` block from the `/16` VPC (room for 4 environments). Within each `/18`, tiers are `/21` subnets (2046 usable hosts), one per AZ.

```
VPC: 10.0.0.0/16
├── prd     (index 0): 10.0.0.0/18
│   ├── web-1a: 10.0.0.0/21
│   ├── web-1b: 10.0.8.0/21
│   ├── app-1a: 10.0.16.0/21
│   └── app-1b: 10.0.24.0/21
├── preprod (index 1): 10.0.64.0/18
│   ├── web-1a: 10.0.64.0/21
│   ├── web-1b: 10.0.72.0/21
│   ├── app-1a: 10.0.80.0/21
│   └── app-1b: 10.0.88.0/21
└── com     (index 2): 10.0.128.0/18
    ├── web-1a: 10.0.128.0/21
    ├── web-1b: 10.0.136.0/21
    ├── db-1a:  10.0.144.0/21
    └── db-1b:  10.0.152.0/21
```

Implementation uses nested `cidrsubnet()`:
- Outer: `cidrsubnet(var.vpc_cidr, 2, env_index)` → `/18` per environment
- Inner: `cidrsubnet(env_cidr, 3, tier_az_index)` → `/21` per subnet

Tier index mapping: `web=0, app=1, db=2`. Each tier gets 2 slots (one per AZ), so `tier_az_index = tier_index * 2 + az_index`.

## NAT Instance (fck-nat)

- **AMI**: fck-nat, latest, arm64 architecture, AL2023-based
- **Instance type**: `t4g.nano` (~$3/mo)
- **Subnet**: first public (web) subnet of the `com` environment
- **source_dest_check**: `false`
- **Security group**: ingress from VPC CIDR (all traffic), unrestricted egress
- **User data**: configure iptables NAT forwarding via fck-nat config
- **Routing**: all private subnets (app, db) route `0.0.0.0/0` through NAT ENI

### NAT Toggle

| `enable_nat_instance` | Subnets | NAT | App route table |
|---|---|---|---|
| `true` | web + app + db | fck-nat t4g.nano | Routes through NAT |
| `false` | web + db only | None | Not created |

When `enable_nat_instance = false`, the `"app"` tier is filtered from all environments at runtime. Users only flip one bool — no need to also edit `environments`.

## Subnet Tags (Standardized Discovery)

Every subnet gets:
```hcl
tags = {
  Name             = "${var.project_code}-${env}-${tier}-${az_short}"
  Environment      = env           # prd, preprod, com
  Tier             = tier          # web, app, db
  SubnetType       = type          # public, private
  AvailabilityZone = az_short      # 1a, 1b
}
```

Consumer projects discover subnets via:
```hcl
data "aws_subnets" "prd_app" {
  filter {
    name   = "tag:Environment"
    values = ["prd"]
  }
  filter {
    name   = "tag:Tier"
    values = ["app"]
  }
}
```

## Route Tables

- **web**: routes `0.0.0.0/0` and `::/0` through IGW (public)
- **app**: routes `0.0.0.0/0` through NAT instance ENI (only when NAT enabled)
- **db**: no internet routes (isolated private)

One route table per tier (shared across environments). Subnets associated by tier.

## Optional Features

All gated behind boolean variables:

### VPC Endpoints (`enable_vpc_endpoints`)
All free-tier endpoints, controlled by a single flag:
- S3 Gateway endpoint (free) — attached to all private route tables (app when NAT enabled, db always)
- DynamoDB Gateway endpoint (free) — attached to all private route tables (app when NAT enabled, db always)
- EC2 Instance Connect Endpoint (free) — in first public subnet, uses NAT instance SG when NAT enabled

### Private DNS (`enable_private_dns`)
- Route53 private hosted zone: `internal.${var.project_code}`
- Associated with the VPC

## Backend Configuration

Backend is configured via `.tfbackend` files, not hardcoded:

```hcl
# main.tf
backend "s3" {}
```

```ini
# backends/sg.tfbackend
bucket               = "my-terraform-state-bucket"
key                  = "vpc.tfstate"
workspace_key_prefix = "tf-state"
region               = "ap-southeast-1"
```

Usage: `terraform init -backend-config=backends/sg.tfbackend`

## Provider

Upgrade from `~>5.31.0` to `~>6.0`.

## Outputs

```hcl
output "vpc_id" { ... }
output "vpc_cidr" { ... }
output "subnet_ids" { ... }           # map: "prd-web" → [subnet-id-1a, subnet-id-1b]
output "nat_instance_id" { ... }      # null when NAT disabled
output "private_zone_id" { ... }      # null when DNS disabled
output "private_zone_name" { ... }    # null when DNS disabled
```

## Deleted Resources

- `modules/natinstance/` directory (flattened into `nat.tf`)
- `ssm.tf` (SSM parameters removed entirely)
- All hardcoded CIDR locals in `subnets.tf`
- Hardcoded backend config in `main.tf`

## CI/CD

`.gitlab-ci.yml` unchanged — it already uses `$CI_PROJECT_DIR` as `TF_DIR`.

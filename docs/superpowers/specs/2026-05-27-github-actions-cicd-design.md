# GitHub Actions CI/CD for Terraform VPC

## Goal

Set up a GitHub Actions CI/CD pipeline for the VPC project using OIDC authentication, auto-semver tagging via conventional commits, and a two-stage deploy workflow (plan+tag on merge, apply on tag).

## Git & Repo Setup

- Create private repo `ShearesWeb/infra-vpc` on GitHub
- Add git remote `shearesweb` pointing to `ShearesWeb/infra-vpc`
- Push `main` branch to the new remote
- Remove the old `.gitlab-ci.yml` file (migrating from GitLab to GitHub)

## Backend Config

- Rename `backends/sg.tfbackend` to `backends/example.tfbackend` with generic placeholder values
- Real per-account `.tfbackend` files stay in git (bucket names are not sensitive)

## Workflow Files

### `.github/workflows/1-merge-request-plan.yml`

**Trigger:** Push to `main` (i.e., when a PR is merged)

**Steps:**
1. Checkout code
2. Configure AWS credentials via OIDC using `aws-actions/configure-aws-credentials@v4`
   - `role-to-assume: ${{ vars.AWS_ROLE_ARN }}`
   - `aws-region: ${{ vars.AWS_REGION }}`
3. Set up Terraform using `hashicorp/setup-terraform@v3`
4. `terraform init -backend-config=${{ vars.BACKEND_CONFIG }}` (no default — must be set per repo)
5. `terraform plan -detailed-exitcode`
6. If plan succeeds (exit code 0 or 2), create a semver tag using `anothrNick/github-tag-action@v1`
   - Parses conventional commits: `fix:` = patch, `feat:` = minor, `BREAKING CHANGE` footer = major
   - Default bump: `patch`
   - Tag prefix: `v`

### `.github/workflows/2-deploy.yml`

**Trigger:** Tag creation matching `v*`

**Steps:**
1. Checkout code at the tag ref
2. Configure AWS credentials via OIDC (same as above)
3. Set up Terraform
4. `terraform init -backend-config=${{ vars.BACKEND_CONFIG }}`
5. `terraform apply -auto-approve`

## GitHub Repository Variables

Set via GitHub repo settings > Settings > Secrets and variables > Actions > Variables:

| Variable | Example Value | Purpose |
|---|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/github-actions-terraform` | IAM role for OIDC |
| `AWS_REGION` | `ap-southeast-1` | Target AWS region |
| `BACKEND_CONFIG` | `backends/sg.tfbackend` | Which `.tfbackend` file to use |

## OIDC Trust Policy

The IAM role in each AWS account needs this trust policy (configured outside this repo):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ShearesWeb/infra-vpc:*"
        }
      }
    }
  ]
}
```

## Permissions

Both workflows need `id-token: write` for OIDC and `contents: write` for tagging:

```yaml
permissions:
  id-token: write
  contents: write
```

## Semver Action

Using `anothrNick/github-tag-action@v1`:
- Reads commit messages since last tag
- `fix:` → patch bump
- `feat:` → minor bump
- `BREAKING CHANGE` in commit body → major bump
- Default bump (no conventional prefix): `patch`
- Creates annotated git tag `vX.Y.Z`

## Deleted Files

- `.gitlab-ci.yml` — replaced by GitHub Actions

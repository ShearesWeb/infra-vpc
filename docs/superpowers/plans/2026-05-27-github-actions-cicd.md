# GitHub Actions CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up GitHub Actions CI/CD with OIDC auth, auto-semver tagging, and terraform plan/apply workflows.

**Architecture:** Two workflow files — plan+tag triggers on PR merge to main, deploy triggers on tag creation. AWS auth via OIDC. Version bumps via commit message tokens (`#major`, `#minor`, `#patch`, default: patch).

**Tech Stack:** GitHub Actions, `aws-actions/configure-aws-credentials@v4`, `hashicorp/setup-terraform@v3`, `anothrNick/github-tag-action@v1`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `.gitlab-ci.yml` | Delete | Old GitLab CI, replaced by GitHub Actions |
| `backends/sg.tfbackend` | Rename to `backends/example.tfbackend` | Generic placeholder backend config |
| `.github/workflows/1-merge-request-plan.yml` | Create | Plan + semver tag on PR merge |
| `.github/workflows/2-deploy.yml` | Create | Apply on tag creation |

---

### Task 1: Clean up old CI and make backend config generic

**Files:**
- Delete: `.gitlab-ci.yml`
- Rename: `backends/sg.tfbackend` → `backends/example.tfbackend`

- [ ] **Step 1: Delete GitLab CI file**

```bash
rm .gitlab-ci.yml
```

- [ ] **Step 2: Rename and rewrite backend config with generic placeholders**

Delete `backends/sg.tfbackend` and create `backends/example.tfbackend`:

```ini
bucket               = "my-terraform-state-bucket"
key                  = "vpc.tfstate"
workspace_key_prefix = "tf-state"
region               = "ap-southeast-1"
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove gitlab-ci, make backend config generic"
```

---

### Task 2: Create GitHub Actions workflow files

**Files:**
- Create: `.github/workflows/1-merge-request-plan.yml`
- Create: `.github/workflows/2-deploy.yml`

- [ ] **Step 1: Create workflow directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create `.github/workflows/1-merge-request-plan.yml`**

```yaml
name: Plan and Tag

on:
  pull_request:
    types:
      - closed
    branches:
      - main

permissions:
  id-token: write
  contents: write

jobs:
  plan:
    if: github.event.pull_request.merged == true
    name: Terraform Plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}
          fetch-depth: "0"

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init -backend-config=${{ vars.BACKEND_CONFIG }}

      - name: Terraform Plan
        run: terraform plan -detailed-exitcode

  tag:
    name: Create Semver Tag
    needs: plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}
          fetch-depth: "0"

      - name: Bump version and push tag
        uses: anothrNick/github-tag-action@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          DEFAULT_BUMP: patch
          TAG_PREFIX: v
```

- [ ] **Step 3: Create `.github/workflows/2-deploy.yml`**

```yaml
name: Deploy

on:
  push:
    tags:
      - "v*"

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    name: Terraform Apply
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init -backend-config=${{ vars.BACKEND_CONFIG }}

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

- [ ] **Step 4: Commit**

```bash
git add .github/
git commit -m "feat: add GitHub Actions workflows for plan and deploy"
```

---

### Task 3: Create GitHub repo, add remote, and push

- [ ] **Step 1: Create private repo**

```bash
gh repo create ShearesWeb/infra-vpc --private --description "Terraform VPC bootstrap infrastructure"
```

- [ ] **Step 2: Add remote**

```bash
git remote add shearesweb git@github.com:ShearesWeb/infra-vpc.git
```

- [ ] **Step 3: Push main branch**

```bash
git push -u shearesweb main
```

- [ ] **Step 4: Verify repo and workflows are visible**

```bash
gh repo view ShearesWeb/infra-vpc
```

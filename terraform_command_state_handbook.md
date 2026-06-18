# Terraform Command & State Management Handbook

**Prepared for:** Fresher → Senior DevOps Engineer → Terraform Architect level  
**Focus:** Practical command usage, state troubleshooting, production-safe execution, and live environment recovery.  
**Recommended Terraform version family:** Terraform v1.x. Always verify your installed version with `terraform version` because command availability can vary by version.

---

## 1. Terraform CLI Mental Model

Terraform is an Infrastructure as Code tool. You write configuration in `.tf` files, Terraform compares that desired configuration with the current state, then creates an execution plan and applies changes to the real infrastructure.

Terraform mainly uses three things:

1. **Configuration** — Your `.tf` files. This is what you want.
2. **State** — Terraform’s mapping between your code and real infrastructure.
3. **Provider APIs** — AWS, Azure, GCP, Kubernetes, GitHub, etc.

Production troubleshooting becomes easy when you remember this equation:

```text
Terraform Plan = Configuration + State + Real Cloud API Refresh
```

If Terraform output is wrong, one of these is usually wrong:

- Code is wrong.
- State is wrong.
- Wrong workspace/environment is selected.
- Backend is wrong.
- Provider credentials/region/account are wrong.
- Someone changed infrastructure manually outside Terraform.

---

## 2. Golden Production Rules

Use these rules before touching live environments:

1. **Never run `apply` directly in production without reviewing `plan`.**
2. **Always use remote backend for team environments.** Example: S3 backend with DynamoDB/S3 native locking, Terraform Cloud/HCP Terraform, AzureRM backend, GCS backend.
3. **Never commit `terraform.tfstate`, `.terraform/`, `.terraform.lock.hcl` exception note:** commit `.terraform.lock.hcl`; do not commit `.terraform/` or local state files.
4. **Always pin provider versions.**
5. **Use separate state per environment.** Example: `dev`, `test`, `prod` should not share the same state file.
6. **Avoid `-target` in normal workflow.** Use it only for emergency recovery or controlled dependency operations.
7. **Avoid manual state editing.** Use `terraform state` commands or configuration blocks like `moved`, `removed`, and `import`.
8. **Do not run two applies at the same time against the same state.** State locking exists to protect you.
9. **Before force-unlock, confirm no active Terraform run is still running.**
10. **Always take a state backup before state surgery.**

---

## 3. Standard Terraform Workflow

### 3.1 Local development workflow

```bash
terraform version
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
```

### 3.2 Production workflow

```bash
terraform version
terraform init -upgrade=false
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform output
```

### 3.3 CI/CD workflow

```bash
terraform init -input=false
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -out=tfplan
terraform show -json tfplan > tfplan.json
terraform apply -input=false tfplan
```

### 3.4 Destroy workflow for non-production

```bash
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

### 3.5 Safer refresh-only workflow

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

---

## 4. Global Terraform CLI Syntax

General syntax:

```bash
terraform [global options] <subcommand> [args]
```

Global options:

```bash
terraform -help
terraform -version
terraform -chdir=DIR <subcommand>
```

Examples:

```bash
terraform -help
terraform -version
terraform -chdir=infra/prod init
terraform -chdir=infra/prod plan
```

Use `-chdir` when running Terraform from a different directory, especially in CI/CD.

---

## 5. Main Terraform Commands Cheat Sheet

| Command | Purpose | Production Usage |
|---|---|---|
| `terraform init` | Initialize working directory, backend, providers, modules | First command after clone or backend/provider/module changes |
| `terraform validate` | Validate syntax and configuration structure | Run before every plan |
| `terraform fmt` | Format `.tf` files | Use `fmt -check` in CI |
| `terraform plan` | Preview infrastructure changes | Mandatory before production apply |
| `terraform apply` | Create/update infrastructure | Use saved plan in production |
| `terraform destroy` | Destroy managed infrastructure | Avoid in production unless approved |
| `terraform output` | Show output values | Useful after apply |
| `terraform show` | Show state or saved plan | Use to inspect plan/state |
| `terraform state` | Advanced state management | Use carefully; backup first |
| `terraform import` | Attach existing resource to state | Used for brownfield/live infra adoption |
| `terraform workspace` | Manage CLI workspaces | Useful for small setups; separate backends preferred for strong prod isolation |
| `terraform force-unlock` | Release stuck state lock | Emergency only |
| `terraform console` | Test expressions | Useful for functions, locals, variable logic |
| `terraform graph` | Generate dependency graph | Useful for architecture/debugging |
| `terraform providers` | Inspect providers | Useful for version/provider troubleshooting |
| `terraform get` | Download/update modules | Usually handled by init, but useful for module refresh |
| `terraform login` | Login to HCP Terraform/private registry | Needed for Terraform Cloud/private modules |
| `terraform logout` | Remove stored credentials | Security cleanup |
| `terraform taint` | Mark resource for recreation | Deprecated; prefer `apply -replace` |
| `terraform untaint` | Remove taint marker | Only when recovering tainted state |
| `terraform test` | Run Terraform tests | Useful for module validation |
| `terraform modules` | Show declared modules | Useful for module audit; requires newer Terraform versions |
| `terraform metadata functions -json` | Show function signatures | Advanced debugging/tooling |
| `terraform stacks` | Manage Terraform Stacks | Advanced HCP/TFE scale workflow |

---

## 6. Core Commands Detailed

## 6.1 `terraform version`

Purpose: Shows Terraform CLI version and provider/plugin info.

```bash
terraform version
terraform -version
```

Use cases:

- Verify local version before production run.
- Check if CI runner and local laptop use same Terraform version.
- Confirm version compatibility with `.terraform.lock.hcl` and backend.

Production tip:

```hcl
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
}
```

---

## 6.2 `terraform init`

Purpose: Prepares the working directory. It initializes backend, downloads providers, downloads modules, and creates `.terraform/` metadata.

Basic:

```bash
terraform init
```

Common options:

```bash
terraform init -upgrade
terraform init -reconfigure
terraform init -migrate-state
terraform init -backend=false
terraform init -backend-config=backend.hcl
terraform init -backend-config="bucket=my-tfstate-bucket"
terraform init -input=false
terraform init -lock=false
terraform init -lock-timeout=5m
```

When to use:

```bash
# First time after clone
terraform init

# Provider/module version upgrade
terraform init -upgrade

# Backend config changed and you want to re-read config
terraform init -reconfigure

# Backend changed and state must move to new backend
terraform init -migrate-state

# CI/CD with backend config file
terraform init -input=false -backend-config=prod.backend.hcl
```

Backend config example:

```hcl
terraform {
  backend "s3" {
    bucket = "company-prod-tfstate"
    key    = "network/prod/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  }
}
```

Production troubleshooting:

| Error | Likely Cause | Fix |
|---|---|---|
| Backend configuration changed | Backend block/key/bucket/region changed | Use `terraform init -reconfigure` or `terraform init -migrate-state` |
| Failed to query provider packages | Network/proxy/registry issue | Check internet/proxy, registry access, plugin cache |
| Inconsistent dependency lock file | `.terraform.lock.hcl` mismatch | Run `terraform init -upgrade` carefully and commit lock file |
| Access denied to S3 backend | AWS IAM issue/wrong profile | Check `aws sts get-caller-identity`, bucket policy, region |

---

## 6.3 `terraform fmt`

Purpose: Formats Terraform files into canonical style.

```bash
terraform fmt
terraform fmt -recursive
terraform fmt -check
terraform fmt -check -recursive
terraform fmt -diff
terraform fmt -write=false
```

Usage:

```bash
# Format current directory
terraform fmt

# Format all child modules
terraform fmt -recursive

# CI check only; fail if files need formatting
terraform fmt -check -recursive

# Show formatting difference
terraform fmt -diff -recursive
```

Production rule: In CI/CD, use:

```bash
terraform fmt -check -recursive
```

---

## 6.4 `terraform validate`

Purpose: Checks whether configuration is syntactically valid and internally consistent.

```bash
terraform validate
terraform validate -json
terraform validate -no-color
```

Use after `init`:

```bash
terraform init
terraform validate
```

Common issues caught:

- Missing required argument.
- Invalid resource type.
- Invalid reference.
- Variable type mismatch.
- Provider block syntax issue.

Important: `validate` does not guarantee cloud permissions or API availability. It validates Terraform configuration, not full production access.

---

## 6.5 `terraform plan`

Purpose: Creates execution plan and previews what Terraform will do.

Basic:

```bash
terraform plan
```

Common options:

```bash
terraform plan -out=tfplan
terraform plan -var="env=prod"
terraform plan -var-file=prod.tfvars
terraform plan -refresh=false
terraform plan -refresh-only
terraform plan -destroy
terraform plan -target=aws_instance.web
terraform plan -replace=aws_instance.web
terraform plan -input=false
terraform plan -lock=false
terraform plan -lock-timeout=5m
terraform plan -detailed-exitcode
terraform plan -no-color
terraform plan -parallelism=5
terraform plan -json
terraform plan -generate-config-out=generated.tf
```

Recommended production command:

```bash
terraform plan -input=false -lock-timeout=5m -var-file=prod.tfvars -out=tfplan
```

Review saved plan:

```bash
terraform show tfplan
terraform show -json tfplan > tfplan.json
```

Plan symbols:

```text
+ create
~ update in-place
-/+ destroy and recreate
- destroy
<= read data source
```

Detailed exit code:

```bash
terraform plan -detailed-exitcode
```

Exit codes:

```text
0 = no changes
1 = error
2 = changes present
```

CI example:

```bash
terraform plan -detailed-exitcode -out=tfplan
code=$?
if [ $code -eq 0 ]; then
  echo "No changes"
elif [ $code -eq 2 ]; then
  echo "Changes detected"
else
  echo "Plan failed"
  exit 1
fi
```

Production warnings:

- Avoid `-target` unless you fully understand dependencies.
- Avoid `-refresh=false` unless provider/API is down and you are doing controlled recovery.
- Always inspect replacements `-/+` in production.
- Treat IAM, security group, route table, subnet, database, and cluster changes as high risk.

---

## 6.6 `terraform apply`

Purpose: Applies changes to real infrastructure.

Basic:

```bash
terraform apply
```

Production-safe:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Common options:

```bash
terraform apply -auto-approve
terraform apply -var="env=prod"
terraform apply -var-file=prod.tfvars
terraform apply -refresh-only
terraform apply -replace=aws_instance.web
terraform apply -target=aws_instance.web
terraform apply -input=false
terraform apply -lock=false
terraform apply -lock-timeout=5m
terraform apply -parallelism=5
terraform apply -no-color
```

Safe replace example:

```bash
terraform plan -replace=aws_instance.web -out=replace.tfplan
terraform show replace.tfplan
terraform apply replace.tfplan
```

Production rule:

```bash
terraform apply tfplan
```

Avoid this in production unless it is a controlled pipeline with approval:

```bash
terraform apply -auto-approve
```

---

## 6.7 `terraform destroy`

Purpose: Destroys all resources managed by the current configuration/state.

```bash
terraform destroy
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Common options:

```bash
terraform destroy -var-file=dev.tfvars
terraform destroy -target=aws_instance.test
terraform destroy -auto-approve
terraform destroy -lock-timeout=5m
terraform destroy -parallelism=5
```

Production warning:

- Do not run `terraform destroy` in production unless there is a formal change approval and backup/rollback plan.
- Confirm current workspace/backend before any destroy.

Pre-destroy checklist:

```bash
terraform workspace show
terraform state list
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
```

---

## 6.8 `terraform output`

Purpose: Shows root module outputs.

```bash
terraform output
terraform output vpc_id
terraform output -json
terraform output -raw kubeconfig
```

Examples:

```bash
terraform output
terraform output alb_dns_name
terraform output -raw db_endpoint
terraform output -json > outputs.json
```

Sensitive outputs:

```hcl
output "db_password" {
  value     = aws_secretsmanager_secret_version.db.secret_string
  sensitive = true
}
```

Important: Sensitive output can still exist in state. Protect the state backend.

---

## 6.9 `terraform show`

Purpose: Shows current state or saved plan.

```bash
terraform show
terraform show tfplan
terraform show -json
terraform show -json tfplan > tfplan.json
```

Use cases:

```bash
# View current state in human-readable form
terraform show

# View saved plan
terraform show tfplan

# Convert plan to JSON for policy/security checks
terraform show -json tfplan > tfplan.json
```

---

## 6.10 `terraform console`

Purpose: Interactive console for testing Terraform expressions.

```bash
terraform console
```

Examples inside console:

```hcl
> upper("prod")
> cidrsubnet("10.0.0.0/16", 8, 1)
> var.environment
> local.common_tags
> aws_vpc.main.id
```

Useful for:

- Testing `cidrsubnet`.
- Testing `merge`, `lookup`, `try`, `can`.
- Debugging locals and variables.

---

## 6.11 `terraform graph`

Purpose: Generates a dependency graph in DOT format.

```bash
terraform graph
terraform graph > graph.dot
terraform graph | dot -Tpng > graph.png
```

Install Graphviz if needed:

```bash
sudo apt-get update
sudo apt-get install -y graphviz
```

Use cases:

- Understand dependency order.
- Debug cyclic dependencies.
- Visualize module/resource relationships.

---

## 6.12 `terraform providers`

Purpose: Shows provider requirements for current configuration and state.

```bash
terraform providers
terraform providers schema -json
terraform providers lock
terraform providers mirror ./providers-mirror
```

Examples:

```bash
terraform providers
terraform providers schema -json > provider-schema.json
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
terraform providers mirror ./provider-cache
```

Use cases:

- Check which modules require which provider.
- Troubleshoot provider version conflicts.
- Pre-download providers for restricted/offline environments.

---

## 6.13 `terraform get`

Purpose: Downloads or updates modules.

```bash
terraform get
terraform get -update
```

Usually `terraform init` handles module download. Use `terraform get -update` when you need to refresh module source separately.

---

## 6.14 `terraform import`

Purpose: Associates existing infrastructure with a Terraform resource address in state.

Classic CLI import:

```bash
terraform import ADDRESS ID
```

Example:

```bash
terraform import aws_instance.web i-0123456789abcdef0
terraform import aws_s3_bucket.logs my-company-logs-bucket
terraform import module.vpc.aws_vpc.main vpc-0123456789abcdef0
```

Important: Classic `terraform import` updates state only. You must already have matching Terraform configuration, or create it immediately.

Recommended process:

```bash
# 1. Write matching resource block first
resource "aws_s3_bucket" "logs" {
  bucket = "my-company-logs-bucket"
}

# 2. Initialize
terraform init

# 3. Import
terraform import aws_s3_bucket.logs my-company-logs-bucket

# 4. Check plan and fix code until no unwanted changes
terraform plan
```

Modern config-driven import example:

```hcl
import {
  to = aws_s3_bucket.logs
  id = "my-company-logs-bucket"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-company-logs-bucket"
}
```

Then:

```bash
terraform plan
terraform apply
```

Generate config for import where supported:

```bash
terraform plan -generate-config-out=generated.tf
```

Production warning:

- Importing the wrong ID to the wrong address can create serious state confusion.
- Always run `terraform state show ADDRESS` after import.
- Always run `terraform plan` after import and ensure Terraform does not want to replace or destroy the imported resource unexpectedly.

---

## 6.15 `terraform login` and `terraform logout`

Purpose: Manage credentials for HCP Terraform, Terraform Enterprise, or private registry.

```bash
terraform login
terraform login app.terraform.io
terraform logout
terraform logout app.terraform.io
```

Use cases:

- Private module registry access.
- HCP Terraform remote operations.
- Terraform Enterprise authentication.

Security:

- Do not commit CLI credentials.
- Rotate tokens when employee leaves/project changes.

---

## 6.16 `terraform force-unlock`

Purpose: Manually unlocks a stuck state lock.

```bash
terraform force-unlock LOCK_ID
terraform force-unlock -force LOCK_ID
```

Use only when:

- A Terraform process crashed.
- CI/CD job was killed.
- Lock remains but no active run exists.

Do not use when:

- Another apply is still running.
- You are not sure who owns the lock.
- You have not checked CI/CD pipeline status.

Checklist before force-unlock:

```bash
# 1. Check no local terraform process is running
ps aux | grep terraform

# 2. Check CI/CD pipeline status
# GitHub Actions/Jenkins/GitLab/HCP Terraform etc.

# 3. Confirm backend/workspace
terraform workspace show

# 4. Unlock only after confirmation
terraform force-unlock LOCK_ID
```

---

## 6.17 `terraform refresh`

Purpose: Updates state to match remote objects.

```bash
terraform refresh
```

Modern safer alternative:

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

Production note: `terraform refresh` is deprecated. Prefer refresh-only plan/apply so you can review the state update before applying it.

---

## 6.18 `terraform taint` and `terraform untaint`

Purpose: Marks/removes resource tainted state.

```bash
terraform taint aws_instance.web
terraform untaint aws_instance.web
```

Modern safer alternative:

```bash
terraform plan -replace=aws_instance.web -out=replace.tfplan
terraform apply replace.tfplan
```

Why prefer `-replace`:

- Replacement intent is visible in the plan.
- No intermediate state snapshot with tainted object.
- Safer for team workflows.

---

## 6.19 `terraform workspace`

Purpose: Manage multiple state workspaces under one configuration/backend.

Commands:

```bash
terraform workspace list
terraform workspace show
terraform workspace new dev
terraform workspace select dev
terraform workspace select -or-create test
terraform workspace delete dev
```

Examples:

```bash
terraform workspace list
terraform workspace new prod
terraform workspace select prod
terraform workspace show
terraform plan -var-file=prod.tfvars
```

Production guidance:

- Workspaces are useful for smaller setups and reusable environments.
- For strict production isolation, prefer separate backend state paths/accounts/projects per environment.
- Always run `terraform workspace show` before `plan`, `apply`, or `destroy`.

Danger example:

```bash
terraform workspace show
# expected: dev
# actual: prod
```

Stop immediately if workspace is wrong.

---

## 6.20 `terraform test`

Purpose: Runs Terraform tests for modules/configuration.

```bash
terraform test
terraform test -verbose
terraform test -filter=tests/vpc.tftest.hcl
```

Useful for:

- Module validation.
- Preventing breaking changes.
- Testing variables, outputs, conditions, and assertions.

Example test file:

```hcl
# tests/vpc.tftest.hcl
run "valid_vpc_plan" {
  command = plan

  assert {
    condition     = var.vpc_cidr != ""
    error_message = "VPC CIDR must not be empty."
  }
}
```

---

## 6.21 `terraform modules`

Purpose: Shows declared modules in the current working directory.

```bash
terraform modules
```

Useful for:

- Auditing module source and versions.
- Checking if modules are pinned.
- Governance and compliance review.

---

## 6.22 `terraform metadata functions`

Purpose: Prints metadata/signatures for Terraform functions.

```bash
terraform metadata functions -json
terraform metadata functions -json > functions.json
```

Useful for advanced tooling, autocomplete, or learning available Terraform functions.

---

## 6.23 `terraform stacks`

Purpose: Manage Terraform Stacks for large-scale HCP Terraform / Terraform Enterprise workflows.

High-level examples:

```bash
terraform stacks -help
terraform stacks init
terraform stacks validate
terraform stacks fmt
terraform stacks providers-lock
```

Stacks are advanced. For normal AWS DevOps project work, master standard Terraform root modules, remote state, modules, and CI/CD first.

---

# 7. Terraform State: Deep Dive

## 7.1 What is Terraform state?

Terraform state is a snapshot that maps Terraform resource addresses to real infrastructure object IDs.

Example mapping:

```text
aws_instance.web  ->  i-0123456789abcdef0
aws_vpc.main      ->  vpc-0123456789abcdef0
aws_s3_bucket.app ->  my-app-bucket
```

Terraform needs state because cloud APIs do not know your Terraform resource names.

---

## 7.2 Why state is sensitive

State may contain:

- Resource IDs.
- IP addresses.
- ARNs.
- Database endpoints.
- User data.
- Secrets depending on provider/resource.
- Sensitive outputs.

Production requirements:

- Store state remotely.
- Enable encryption.
- Enable versioning.
- Restrict IAM access.
- Enable state locking.
- Do not send state file in chat/email/ticket unless sanitized.

---

## 7.3 Local vs Remote State

### Local state

Default file:

```bash
terraform.tfstate
```

Backup:

```bash
terraform.tfstate.backup
```

Local state is okay only for learning or personal labs.

### Remote state

Examples:

- AWS S3 backend.
- Terraform Cloud / HCP Terraform.
- AzureRM backend.
- GCS backend.
- Consul backend.

Production recommendation: Use remote state with locking and encryption.

---

## 7.4 State locking

State locking prevents multiple people/pipelines from modifying the same state at the same time.

Common lock error:

```text
Error acquiring the state lock
```

Correct action:

1. Check if another Terraform run is active.
2. Wait or cancel safely.
3. Force unlock only after confirming it is stale.

---

# 8. Terraform State Commands Cheat Sheet

| Command | Purpose | Safe? | Production Notes |
|---|---|---|---|
| `terraform state list` | List resources in state | Read-only | Safe |
| `terraform state show ADDRESS` | Show one resource from state | Read-only | Safe, may expose sensitive values |
| `terraform state pull` | Download state to stdout | Read-only | Protect output file |
| `terraform state push PATH` | Upload local state to backend | Dangerous | Last-resort disaster recovery only |
| `terraform state mv SRC DST` | Move/rename resource address in state | Modifies state | Prefer `moved` block when possible |
| `terraform state rm ADDRESS` | Remove resource from state without destroying infra | Modifies state | Prefer `removed` block when possible |
| `terraform state replace-provider` | Replace provider source address in state | Modifies state | Useful after provider namespace migration |

---

## 8.1 `terraform state list`

Purpose: Lists all resources tracked in state.

```bash
terraform state list
```

Examples:

```bash
terraform state list
terraform state list | grep aws_instance
terraform state list | grep module.vpc
terraform state list 'module.vpc.*'
```

Use cases:

- Confirm if a resource is managed by Terraform.
- Find exact resource address.
- Check module paths.
- Prepare for `state show`, `state mv`, `state rm`, `import`, or `-replace`.

Example output:

```text
aws_vpc.main
aws_subnet.public[0]
aws_subnet.public[1]
module.eks.aws_eks_cluster.this
module.eks.aws_iam_role.cluster
```

---

## 8.2 `terraform state show`

Purpose: Shows attributes of a specific resource in state.

```bash
terraform state show ADDRESS
```

Examples:

```bash
terraform state show aws_vpc.main
terraform state show 'aws_instance.web[0]'
terraform state show 'aws_security_group.app["web"]'
terraform state show module.vpc.aws_vpc.main
```

Use cases:

- Find real cloud ID.
- Check current tags/attributes in state.
- Confirm import result.
- Troubleshoot drift.

Warning: Output may include sensitive values.

---

## 8.3 `terraform state pull`

Purpose: Downloads current state and prints it to stdout.

```bash
terraform state pull
```

Safe backup:

```bash
terraform state pull > state-backup-$(date +%F-%H%M%S).tfstate
```

Inspect with jq:

```bash
terraform state pull | jq '.resources[].type' | sort | uniq
terraform state pull | jq '.serial, .lineage, .terraform_version'
```

Use cases:

- Emergency backup before state surgery.
- Audit state metadata.
- Compare state versions.

Security:

- Treat backup as secret.
- Do not commit to Git.
- Delete local backup after work if policy requires.

---

## 8.4 `terraform state push`

Purpose: Uploads a local state file to the configured backend.

```bash
terraform state push PATH
terraform state push state-backup.tfstate
terraform state push -force state-fixed.tfstate
```

Use only when:

- Backend state is corrupted.
- You are doing disaster recovery.
- HashiCorp/support/team lead approves.
- You have backups and a rollback path.

Danger:

- Wrong push can overwrite good remote state.
- Can disconnect Terraform from real infrastructure.
- Can cause duplicate creation or destroy plans.

Safer process:

```bash
# 1. Pull current remote state
terraform state pull > remote-before.tfstate

# 2. Copy backup to working file
cp remote-before.tfstate fixed.tfstate

# 3. Modify only if absolutely required and reviewed

# 4. Push only after approval
terraform state push fixed.tfstate

# 5. Validate
terraform plan
```

Avoid `-force` unless you fully understand lineage and serial safety checks.

---

## 8.5 `terraform state mv`

Purpose: Moves resource address in state. Used when renaming resources or moving resources into modules without recreation.

```bash
terraform state mv SOURCE DESTINATION
```

Examples:

```bash
terraform state mv aws_instance.web aws_instance.app
terraform state mv aws_instance.web module.compute.aws_instance.web
terraform state mv 'aws_subnet.public[0]' 'aws_subnet.public["az1"]'
terraform state mv -state-out=../new/terraform.tfstate aws_instance.web aws_instance.web
```

Before:

```hcl
resource "aws_instance" "web" {}
```

After:

```hcl
resource "aws_instance" "app" {}
```

Command:

```bash
terraform state mv aws_instance.web aws_instance.app
terraform plan
```

Modern safer alternative: `moved` block.

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.app
}
```

Then:

```bash
terraform plan
terraform apply
```

Use `moved` block when possible because it is version-controlled and visible to reviewers.

---

## 8.6 `terraform state rm`

Purpose: Removes resource from state without destroying the real infrastructure.

```bash
terraform state rm ADDRESS
```

Examples:

```bash
terraform state rm aws_instance.web
terraform state rm 'aws_instance.web[0]'
terraform state rm 'aws_security_group.app["web"]'
terraform state rm module.legacy.aws_instance.old
terraform state rm module.legacy
terraform state rm -dry-run aws_instance.web
```

Use cases:

- Stop managing a resource with Terraform but keep it running.
- Resource moved to another Terraform state.
- Resource imported into wrong address and must be forgotten.

Danger:

- Terraform forgets the resource.
- Next plan may try to recreate it if config still exists.
- Cloud resource remains alive and may become unmanaged drift.

Correct process:

```bash
terraform state pull > backup-before-rm.tfstate
terraform state rm -dry-run aws_instance.web
terraform state rm aws_instance.web
terraform plan
```

Modern safer alternative: `removed` block.

```hcl
removed {
  from = aws_instance.web

  lifecycle {
    destroy = false
  }
}
```

Then:

```bash
terraform plan
terraform apply
```

---

## 8.7 `terraform state replace-provider`

Purpose: Replaces provider source address in the state.

```bash
terraform state replace-provider FROM_PROVIDER_FQN TO_PROVIDER_FQN
```

Example:

```bash
terraform state replace-provider registry.terraform.io/-/aws registry.terraform.io/hashicorp/aws
```

Use cases:

- Provider namespace changed.
- Migrating from old provider source address.
- Forked provider migration.

Process:

```bash
terraform state pull > backup-before-provider-replace.tfstate
terraform providers
terraform state replace-provider registry.terraform.io/-/aws registry.terraform.io/hashicorp/aws
terraform init
terraform plan
```

---

# 9. Resource Addressing for State Commands

Terraform addresses are critical for state commands.

## 9.1 Basic resource

```bash
aws_instance.web
```

## 9.2 Resource inside module

```bash
module.vpc.aws_vpc.main
module.eks.aws_eks_cluster.this
```

## 9.3 Count-based resource

```bash
aws_instance.web[0]
aws_instance.web[1]
```

Use quotes in shell:

```bash
terraform state show 'aws_instance.web[0]'
```

## 9.4 For_each-based resource

```bash
aws_security_group_rule.ingress["ssh"]
```

Use quotes:

```bash
terraform state show 'aws_security_group_rule.ingress["ssh"]'
```

## 9.5 Module with count/for_each

```bash
module.app[0].aws_instance.web
module.app["prod"].aws_instance.web
```

---

# 10. Import, Move, Remove: Which One to Use?

| Scenario | Correct Action |
|---|---|
| Resource exists in AWS but not in Terraform state | `terraform import` or `import` block |
| Resource is in state but resource name changed in code | `moved` block or `terraform state mv` |
| Resource should remain in AWS but Terraform should stop managing it | `removed` block or `terraform state rm` |
| Resource is broken and must be recreated | `terraform apply -replace=ADDRESS` |
| State lock is stuck | `terraform force-unlock LOCK_ID` after checks |
| Provider namespace changed | `terraform state replace-provider` |
| Need to inspect resource state | `terraform state show ADDRESS` |
| Need to backup state | `terraform state pull > backup.tfstate` |

---

# 11. Troubleshooting Playbooks

## 11.1 `terraform init` fails

Symptoms:

```text
Error: Failed to query available provider packages
Error: Backend configuration changed
AccessDenied: Access Denied
```

Checklist:

```bash
terraform version
pwd
ls -la
cat versions.tf
cat backend.tf
aws sts get-caller-identity
terraform init -reconfigure
```

Fix by situation:

```bash
# Provider/module upgrade issue
terraform init -upgrade

# Backend changed but state should not migrate
terraform init -reconfigure

# Backend changed and state must migrate
terraform init -migrate-state

# Non-interactive CI
terraform init -input=false -backend-config=prod.backend.hcl
```

---

## 11.2 Plan shows unexpected destroy

Immediate action: Do not apply.

Checklist:

```bash
terraform workspace show
terraform state list
terraform plan -out=tfplan
terraform show tfplan
terraform show -json tfplan > tfplan.json
```

Common reasons:

- Resource removed from code.
- Wrong workspace selected.
- Wrong backend key selected.
- Resource address changed without `moved` block.
- Variable file missing or wrong.
- Provider default region/account changed.
- Manual cloud-side change caused replacement.

Fix examples:

```hcl
# If resource was renamed
moved {
  from = aws_instance.old
  to   = aws_instance.new
}
```

```bash
# If wrong workspace
terraform workspace select prod

# If wrong var file
terraform plan -var-file=prod.tfvars
```

---

## 11.3 State lock error

Error:

```text
Error acquiring the state lock
Lock Info:
  ID:        xxxxx
  Operation: OperationTypeApply
```

Checklist:

```bash
ps aux | grep terraform
terraform workspace show
# Check CI/CD pipeline
# Check HCP Terraform/TFE runs if used
```

If stale:

```bash
terraform force-unlock LOCK_ID
```

If non-interactive approved emergency:

```bash
terraform force-unlock -force LOCK_ID
```

Never unlock active apply.

---

## 11.4 Resource already exists error

Error:

```text
EntityAlreadyExists
AlreadyExistsException
BucketAlreadyOwnedByYou
InvalidGroup.Duplicate
```

Cause: Resource exists in cloud but not in Terraform state.

Fix:

```bash
# 1. Add resource block
# 2. Import existing resource
terraform import aws_s3_bucket.logs my-existing-bucket

# 3. Inspect
terraform state show aws_s3_bucket.logs

# 4. Plan
terraform plan
```

---

## 11.5 Resource manually deleted from cloud

Symptoms:

- Plan wants to create resource again.
- Refresh errors with not found.

Commands:

```bash
terraform plan
terraform apply
```

If resource should not be recreated:

```bash
terraform state rm ADDRESS
```

Or:

```hcl
removed {
  from = ADDRESS
  lifecycle {
    destroy = false
  }
}
```

---

## 11.6 Resource manually changed in cloud / drift

Detect:

```bash
terraform plan
terraform plan -refresh-only
```

Options:

1. Accept drift into state only:

```bash
terraform apply -refresh-only
```

2. Revert cloud to code:

```bash
terraform apply
```

3. Update code to match approved manual change:

```bash
# edit .tf files
terraform plan
terraform apply
```

Production tip: Do not blindly apply. First confirm if manual change was emergency fix.

---

## 11.7 Apply failed halfway

Example:

```text
Error: creating RDS instance timeout
```

Checklist:

```bash
terraform state list
terraform plan
terraform state show ADDRESS
```

Understand:

- Terraform may have created some resources before failing.
- State may or may not have recorded the resource depending on failure timing.
- Run `plan` again; Terraform usually converges.

Recovery:

```bash
terraform plan -out=recovery.tfplan
terraform show recovery.tfplan
terraform apply recovery.tfplan
```

If resource exists but not in state:

```bash
terraform import ADDRESS REAL_ID
terraform plan
```

---

## 11.8 Wrong resource name refactor caused destroy/create

Bad change:

```hcl
# old
resource "aws_instance" "web" {}

# new
resource "aws_instance" "app" {}
```

Terraform sees:

```text
- destroy aws_instance.web
+ create aws_instance.app
```

Fix with moved block:

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.app
}
```

Then:

```bash
terraform plan
terraform apply
```

Alternative state command:

```bash
terraform state mv aws_instance.web aws_instance.app
terraform plan
```

---

## 11.9 Need to recreate only one resource

Preferred:

```bash
terraform plan -replace=aws_instance.web -out=replace.tfplan
terraform apply replace.tfplan
```

Avoid old pattern:

```bash
terraform taint aws_instance.web
terraform apply
```

---

## 11.10 Need to change only one resource urgently

Possible but dangerous:

```bash
terraform plan -target=aws_instance.web
terraform apply -target=aws_instance.web
```

Use `-target` only when:

- Dependency is understood.
- Emergency fix required.
- You will run full `terraform plan` after.

After targeted apply:

```bash
terraform plan
```

---

## 11.11 Wrong workspace applied

Checklist:

```bash
terraform workspace list
terraform workspace show
terraform state list
```

If no damage yet:

```bash
terraform workspace select correct-env
terraform plan
```

If damage occurred:

1. Stop further applies.
2. Save state backup.
3. Compare cloud resources and state.
4. Decide whether to import/move/remove.
5. Execute recovery plan with approval.

---

## 11.12 Backend key points to wrong state

Symptoms:

- Terraform wants to create everything.
- Terraform state list is empty unexpectedly.
- Plan shows massive changes.

Commands:

```bash
terraform state list
cat backend.tf
terraform init -reconfigure
```

Check S3 backend key:

```hcl
key = "network/prod/terraform.tfstate"
```

Ensure you are not using dev key for prod or prod key for dev.

---

# 12. AWS Production Backend Example

## 12.1 S3 backend pattern

```hcl
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  backend "s3" {
    bucket  = "company-terraform-state-prod"
    key     = "aws/network/prod/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Initialize:

```bash
terraform init
```

With backend file:

```bash
terraform init -backend-config=prod.backend.hcl
```

Example `prod.backend.hcl`:

```hcl
bucket  = "company-terraform-state-prod"
key     = "aws/network/prod/terraform.tfstate"
region  = "ap-south-1"
encrypt = true
```

## 12.2 State backup before risky operation

```bash
mkdir -p tfstate-backups
terraform state pull > tfstate-backups/prod-$(date +%F-%H%M%S).tfstate
```

## 12.3 AWS identity check before production plan/apply

```bash
aws sts get-caller-identity
aws configure list
terraform workspace show
terraform plan -var-file=prod.tfvars -out=tfplan
```

---

# 13. Variables and Input Commands

## 13.1 Variable precedence basics

Common input methods:

```bash
terraform plan -var="env=prod"
terraform plan -var-file=prod.tfvars
TF_VAR_env=prod terraform plan
```

File examples:

```text
terraform.tfvars
auto.tfvars
prod.tfvars
```

## 13.2 Production usage

```bash
terraform plan -var-file=environments/prod.tfvars -out=tfplan
terraform apply tfplan
```

Avoid manually typing many `-var` values in production. Prefer reviewed `.tfvars` files or secure CI/CD variables.

---

# 14. Useful Environment Variables

| Variable | Purpose | Example |
|---|---|---|
| `TF_LOG` | Enable logs | `TF_LOG=DEBUG terraform plan` |
| `TF_LOG_PATH` | Write logs to file | `TF_LOG_PATH=tf.log` |
| `TF_VAR_name` | Pass variable | `TF_VAR_env=prod` |
| `TF_CLI_ARGS` | Add args globally | `TF_CLI_ARGS="-no-color"` |
| `TF_CLI_ARGS_plan` | Add args only to plan | `TF_CLI_ARGS_plan="-lock-timeout=5m"` |
| `TF_INPUT` | Disable prompts | `TF_INPUT=0` |
| `TF_IN_AUTOMATION` | Automation mode | `TF_IN_AUTOMATION=1` |
| `TF_DATA_DIR` | Change `.terraform` data dir | `TF_DATA_DIR=/tmp/tfdata` |
| `TF_WORKSPACE` | Select workspace non-interactively | `TF_WORKSPACE=prod` |
| `TF_PLUGIN_CACHE_DIR` | Cache provider plugins | `TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache` |

Debug example:

```bash
TF_LOG=DEBUG TF_LOG_PATH=terraform-debug.log terraform plan
```

CI example:

```bash
export TF_IN_AUTOMATION=1
export TF_INPUT=0
terraform init -input=false
terraform plan -input=false -out=tfplan
```

---

# 15. Lock File and Provider Version Commands

`.terraform.lock.hcl` records provider selections and hashes.

Production guidance:

- Commit `.terraform.lock.hcl`.
- Review lock changes in PR.
- Run `terraform init -upgrade` intentionally, not randomly.

Commands:

```bash
terraform init
terraform init -upgrade
terraform providers
terraform providers lock
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

---

# 16. CI/CD Production Pipeline Command Sequence

## 16.1 Pull request pipeline

```bash
terraform init -input=false
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -out=tfplan
terraform show -json tfplan > tfplan.json
```

## 16.2 Approved deployment pipeline

```bash
terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

## 16.3 Why saved plan is better

Bad:

```bash
terraform plan
terraform apply
```

Between plan and apply, code or variables may change.

Better:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

This applies exactly the reviewed plan.

---

# 17. Command Patterns for Common AWS Scenarios

## 17.1 Create VPC

```bash
terraform init
terraform validate
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
terraform output
```

## 17.2 Import existing S3 bucket

```bash
terraform import aws_s3_bucket.logs my-existing-bucket
terraform state show aws_s3_bucket.logs
terraform plan
```

## 17.3 Move VPC resource into module

```hcl
moved {
  from = aws_vpc.main
  to   = module.vpc.aws_vpc.main
}
```

```bash
terraform plan
terraform apply
```

Or:

```bash
terraform state mv aws_vpc.main module.vpc.aws_vpc.main
terraform plan
```

## 17.4 Recreate one EC2 instance

```bash
terraform plan -replace=aws_instance.web -out=replace.tfplan
terraform apply replace.tfplan
```

## 17.5 Stop managing manually owned bucket but keep bucket

```hcl
removed {
  from = aws_s3_bucket.legacy

  lifecycle {
    destroy = false
  }
}
```

```bash
terraform plan
terraform apply
```

Or legacy:

```bash
terraform state rm aws_s3_bucket.legacy
```

## 17.6 Show all resources in EKS module

```bash
terraform state list | grep module.eks
```

## 17.7 Check exact EKS cluster state

```bash
terraform state show module.eks.aws_eks_cluster.this
```

---

# 18. State Surgery Standard Operating Procedure

Use this whenever you run `state mv`, `state rm`, `replace-provider`, or `push`.

## 18.1 Before

```bash
terraform version
terraform workspace show
terraform state list
terraform plan
mkdir -p state-backups
terraform state pull > state-backups/before-$(date +%F-%H%M%S).tfstate
```

## 18.2 Execute one change only

Example:

```bash
terraform state mv aws_instance.web aws_instance.app
```

## 18.3 Validate

```bash
terraform state list
terraform plan
```

## 18.4 If wrong

Do not panic. Stop and use backup.

```bash
terraform state push state-backups/before-YYYY-MM-DD-HHMMSS.tfstate
terraform plan
```

Only push backup if you are absolutely sure and authorized.

---

# 19. Terraform Files You Must Know

| File/Directory | Purpose | Commit? |
|---|---|---|
| `main.tf` | Main resources | Yes |
| `variables.tf` | Input variables | Yes |
| `outputs.tf` | Outputs | Yes |
| `providers.tf` | Providers | Yes |
| `versions.tf` | Required Terraform/provider versions | Yes |
| `terraform.tfvars` | Variable values | Depends; not if secrets |
| `prod.tfvars` | Environment values | Depends; avoid secrets |
| `.terraform.lock.hcl` | Provider lock file | Yes |
| `.terraform/` | Downloaded providers/modules/backend metadata | No |
| `terraform.tfstate` | Local state | No |
| `terraform.tfstate.backup` | Local state backup | No |
| `tfplan` | Saved plan | Usually no; short-lived artifact only |

`.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
!example.tfvars
*.tfplan
terraform-debug.log
```

Note: Some teams commit non-sensitive `.tfvars`; never commit secrets.

---

# 20. Dangerous Commands and Safer Alternatives

| Risky Command | Risk | Safer Alternative |
|---|---|---|
| `terraform apply -auto-approve` | No manual approval | Use saved plan with approval |
| `terraform destroy -auto-approve` | Full environment deletion | Use `plan -destroy` and approval |
| `terraform force-unlock -force` | Can corrupt active run | Confirm no active run first |
| `terraform state push -force` | Can overwrite good state | Avoid unless disaster recovery |
| `terraform state rm` | Resource becomes unmanaged | Use `removed` block if possible |
| `terraform state mv` | Wrong mapping if misused | Use `moved` block if possible |
| `terraform plan/apply -target` | Skips full dependency view | Run full plan after target operation |
| `terraform plan -refresh=false` | Ignores real-world drift | Use normal refresh unless emergency |
| `terraform taint` | Deprecated workflow | Use `apply -replace` |

---

# 21. Interview-Ready Explanations

## 21.1 What happens when we run `terraform init`?

Terraform initializes the working directory. It configures backend, downloads required providers, downloads modules, and prepares `.terraform/` metadata. It is safe to run multiple times. If backend or provider versions change, we rerun `init`.

## 21.2 What happens when we run `terraform plan`?

Terraform refreshes current state from real infrastructure, compares the state and configuration, and shows the actions required to make real infrastructure match the code. It does not change infrastructure.

## 21.3 What happens when we run `terraform apply`?

Terraform executes the proposed plan and creates, updates, replaces, or destroys real infrastructure objects. In production, we usually apply a saved plan file to ensure we apply exactly what was reviewed.

## 21.4 What is Terraform state?

Terraform state is the mapping between Terraform resource addresses and real infrastructure object IDs. Terraform needs state to know which real resource belongs to which resource block in code.

## 21.5 How do you recover from state lock?

First I check if any Terraform run is active locally or in CI/CD. If no active run exists and the lock is stale, I use `terraform force-unlock LOCK_ID`. I never force-unlock without confirming because it can corrupt state if another apply is running.

## 21.6 How do you import an existing AWS resource?

I write the matching Terraform resource block, run `terraform import ADDRESS ID`, verify with `terraform state show ADDRESS`, then run `terraform plan` and adjust the code until there are no unwanted changes.

## 21.7 How do you rename a resource without destroying it?

Use a `moved` block in code or `terraform state mv`. The `moved` block is preferred because it is version-controlled and visible in code review.

## 21.8 How do you stop Terraform from managing a resource but keep it in AWS?

Use a `removed` block with `destroy = false`, or use `terraform state rm ADDRESS`. Then run `terraform plan` to ensure Terraform will not recreate or destroy it unexpectedly.

---

# 22. Complete Command Reference Quick List

```bash
# Help/version/global
terraform
terraform -help
terraform -version
terraform -chdir=DIR <subcommand>
terraform version

# Init/backend/modules/providers
terraform init
terraform init -upgrade
terraform init -reconfigure
terraform init -migrate-state
terraform init -backend-config=backend.hcl
terraform init -input=false
terraform get
terraform get -update
terraform providers
terraform providers schema -json
terraform providers lock
terraform providers mirror ./mirror

# Formatting/validation/testing
terraform fmt
terraform fmt -recursive
terraform fmt -check -recursive
terraform validate
terraform validate -json
terraform test
terraform test -verbose

# Plan/apply/destroy
terraform plan
terraform plan -out=tfplan
terraform plan -var="key=value"
terraform plan -var-file=prod.tfvars
terraform plan -refresh-only
terraform plan -destroy
terraform plan -replace=ADDRESS
terraform plan -target=ADDRESS
terraform plan -detailed-exitcode
terraform plan -generate-config-out=generated.tf
terraform apply
terraform apply tfplan
terraform apply -auto-approve
terraform apply -refresh-only
terraform apply -replace=ADDRESS
terraform destroy
terraform destroy -target=ADDRESS

# Inspect
terraform output
terraform output -json
terraform output -raw NAME
terraform show
terraform show tfplan
terraform show -json tfplan
terraform console
terraform graph
terraform graph | dot -Tpng > graph.png
terraform modules
terraform metadata functions -json

# Import/refactor
terraform import ADDRESS ID
terraform taint ADDRESS
terraform untaint ADDRESS

# State
terraform state list
terraform state show ADDRESS
terraform state pull
terraform state pull > backup.tfstate
terraform state push backup.tfstate
terraform state mv SOURCE DESTINATION
terraform state rm ADDRESS
terraform state rm -dry-run ADDRESS
terraform state replace-provider FROM_PROVIDER TO_PROVIDER

# Locking
terraform force-unlock LOCK_ID
terraform force-unlock -force LOCK_ID

# Workspace
terraform workspace list
terraform workspace show
terraform workspace new NAME
terraform workspace select NAME
terraform workspace select -or-create NAME
terraform workspace delete NAME

# Auth / HCP Terraform / Registry
terraform login
terraform login app.terraform.io
terraform logout
terraform logout app.terraform.io

# Stacks - advanced
terraform stacks -help
terraform stacks init
terraform stacks validate
terraform stacks fmt
terraform stacks providers-lock
```

---

# 23. Production Readiness Checklist

Before production `apply`:

```bash
terraform version
aws sts get-caller-identity
terraform workspace show
terraform init -input=false
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -lock-timeout=5m -var-file=prod.tfvars -out=tfplan
terraform show tfplan
```

Ask:

- Am I in the right AWS account?
- Am I in the right region?
- Am I using the right backend key?
- Am I using the right workspace?
- Are there any unexpected destroys/replacements?
- Are IAM/security/network/database changes reviewed?
- Is there a rollback plan?
- Is state backend healthy and locked?
- Are secrets protected?

Apply:

```bash
terraform apply -input=false tfplan
```

After apply:

```bash
terraform output
terraform plan
```

The final `terraform plan` should ideally show no changes.

---

# 24. Fast Troubleshooting Command Set

When something is wrong, start here:

```bash
terraform version
terraform workspace show
terraform state list
terraform providers
terraform validate
terraform plan
```

For AWS:

```bash
aws sts get-caller-identity
aws configure list
```

For state backup:

```bash
terraform state pull > backup-$(date +%F-%H%M%S).tfstate
```

For exact resource inspection:

```bash
terraform state show ADDRESS
```

For drift:

```bash
terraform plan -refresh-only
```

For stuck lock:

```bash
terraform force-unlock LOCK_ID
```

For resource recreation:

```bash
terraform plan -replace=ADDRESS -out=replace.tfplan
terraform apply replace.tfplan
```

For rename/move:

```hcl
moved {
  from = old_address
  to   = new_address
}
```

For unmanaged existing resource:

```bash
terraform import ADDRESS ID
```

For stop managing but keep resource:

```hcl
removed {
  from = ADDRESS
  lifecycle {
    destroy = false
  }
}
```

---

# 25. Final Architect-Level Advice

At fresher level, learn `init`, `fmt`, `validate`, `plan`, `apply`, and `destroy`.

At engineer level, master variables, modules, remote state, workspaces, imports, and CI/CD plan/apply flow.

At senior/architect level, master state recovery, refactoring without downtime, drift management, provider upgrades, backend migration, policy checks, module versioning, secure state design, and production change control.

In live production, the best Terraform engineer is not the person who knows the most commands. It is the person who knows exactly which command **not** to run.

---

## Official References Used

- Terraform CLI commands overview: https://developer.hashicorp.com/terraform/cli/commands
- Terraform init: https://developer.hashicorp.com/terraform/cli/commands/init
- Terraform plan: https://developer.hashicorp.com/terraform/cli/commands/plan
- Terraform apply: https://developer.hashicorp.com/terraform/cli/commands/apply
- Terraform destroy: https://developer.hashicorp.com/terraform/cli/commands/destroy
- Terraform state commands: https://developer.hashicorp.com/terraform/cli/commands/state
- Terraform state rm: https://developer.hashicorp.com/terraform/cli/commands/state/rm
- Terraform state push: https://developer.hashicorp.com/terraform/cli/commands/state/push
- Terraform force-unlock: https://developer.hashicorp.com/terraform/cli/commands/force-unlock
- Terraform refresh: https://developer.hashicorp.com/terraform/cli/commands/refresh
- Terraform import: https://developer.hashicorp.com/terraform/cli/import
- Terraform moved block: https://developer.hashicorp.com/terraform/language/block/moved
- Terraform workspaces: https://developer.hashicorp.com/terraform/cli/workspaces
- Terraform tests: https://developer.hashicorp.com/terraform/language/tests

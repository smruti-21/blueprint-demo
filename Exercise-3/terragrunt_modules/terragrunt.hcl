# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Configure Terragrunt to automatically store tfstate files in an S3 bucket

locals {
  default_yaml_path  = find_in_parent_folders("empty.yaml")
  terragrunt_modules = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(basename ${get_terragrunt_dir()})")
  full_path          = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(dirname ${get_terragrunt_dir()})")
  parent_folder      = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(basename ${local.full_path})")
  tag                = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n ${local.parent_folder} | sed -e s/_/-/g")
  conf_location      = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(dirname ${find_in_parent_folders("empty.yaml")})/${get_env("CONFIG_DIR")}/${get_env("CONFIG_FILE")}")
  conf               = yamldecode(file("${local.conf_location}"))
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = "${get_aws_account_id()}-${get_env("TF_VAR_aws_region", "")}-tfstate"
    key            = "${local.parent_folder}/${local.terragrunt_modules}/terraform-${get_env("ENV", "")}-${get_env("TF_VAR_aws_region", "")}.tfstate"
    region         = "${get_env("TF_VAR_aws_region", "")}"
    dynamodb_table = "dynamo_lock_table"
    profile        = "${get_env("TF_VAR_aws_profile", "")}"
  }
}

terraform {
  extra_arguments "retry_lock" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    arguments = [
      "-lock-timeout=20m"
    ]
  }
  extra_arguments "regional_state_file" {
    commands = [
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    arguments = [
      "-state=terraform-${get_env("ENV", "")}-${get_env("TF_VAR_aws_region", "")}.tfstate"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------


# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  # Configure Terragrunt to use common vars encoded as yaml to help you keep often-repeated variables (e.g., account ID)
  # DRY. We use yamldecode to merge the maps into the inputs, as opposed to using varfiles due to a restriction in
  # Terraform >=0.12 that all vars must be defined as variable blocks in modules. Terragrunt inputs are not affected by
  # this restriction.
)

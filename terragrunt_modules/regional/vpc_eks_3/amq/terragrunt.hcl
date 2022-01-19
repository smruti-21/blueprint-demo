locals {
  terragrunt_modules = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(basename ${get_terragrunt_dir()})")
  full_path          = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(dirname ${get_terragrunt_dir()})")
  parent_folder      = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(basename ${local.full_path})")
  tag                = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n ${local.parent_folder} | sed -e s/_/-/g")
  conf_location      = run_cmd("--terragrunt-quiet", "bash", "-c", "echo -n $(dirname ${find_in_parent_folders("empty.yaml")})/${get_env("CONFIG_DIR")}/${get_env("CONFIG_FILE")}")
  scope              = run_cmd("--terragrunt-quiet", "bash", "-c", "pwd | grep '/global/' >>/dev/null  && echo global || echo regional ")
  conf               = yamldecode(file("${local.conf_location}"))
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = "${get_aws_account_id()}-${get_env("TF_VAR_aws_region", "")}-tfstate"
    key            = "${local.scope}/${local.parent_folder}/${local.terragrunt_modules}/terraform-${get_env("ENV", "")}-${get_env("TF_VAR_aws_region", "")}.tfstate"
    region         = "${get_env("TF_VAR_aws_region", "")}"
    dynamodb_table = "dynamo_lock_table"
    profile        = "${get_env("TF_VAR_aws_profile", "")}"
  }
}

terraform {
  source = local.conf["terragrunt_modules_settings"]["${local.scope}"]["${local.parent_folder}"]["${local.terragrunt_modules}"]["repo"]
  before_hook "before_hook" {
    commands = ["apply", "plan"]
    execute  = ["echo", "---------------START: ${local.parent_folder}/${local.terragrunt_modules} ----------------- "]
  }

  after_hook "after_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "---------------END: ${local.parent_folder}/${local.terragrunt_modules} ----------------- "]
    run_on_error = true
  }
}


dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    private_subnets           = ["placeholder"]
    vpc_id                    = "vpc"
    default_security_group_id = "sg-123123123"
  }
}

dependency "amq_sec_group" {
  config_path = "../amq_sec_group"
  mock_outputs = {
    security_group_id = ["placeholder"]
  }
}

inputs = merge(
  local.conf["terragrunt_modules_settings"]["${local.scope}"]["${local.parent_folder}"]["${local.terragrunt_modules}"]["tf_variables"],
  {
    subnet_ids                   = [dependency.networking.outputs.private_subnets[0]]
    vpc_id                       = dependency.networking.outputs.vpc_id
    use_existing_security_groups = "true"
    existing_security_groups     = [dependency.amq_sec_group.outputs.security_group_id]
  },
)
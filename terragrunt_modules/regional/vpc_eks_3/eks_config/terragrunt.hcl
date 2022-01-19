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
  before_hook "init" {
    commands = ["apply", "plan"]
    execute  = ["terraform", "init"]
  }
  after_hook "after_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "---------------END: ${local.parent_folder}/${local.terragrunt_modules} ----------------- "]
    run_on_error = true
  }
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_endpoint                   = "placeholder"
    cluster_certificate_authority_data = "cGxhY2Vob2xkZXI="
    worker_security_group_id           = "placeholder"
    cluster_id                         = "placeholder"
  }
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    public_subnets  = ["placeholder"]
    private_subnets = ["placeholder"]
    vpc_id          = "placeholder"
  }
}

inputs = merge(
  local.conf["terragrunt_modules_settings"]["${local.scope}"]["${local.parent_folder}"]["${local.terragrunt_modules}"]["tf_variables"],
  {
    host                     = dependency.eks.outputs.cluster_endpoint
    cluster_ca_certificate   = base64decode(dependency.eks.outputs.cluster_certificate_authority_data)
    cluster_id               = dependency.eks.outputs.cluster_id
    worker_security_group_id = dependency.eks.outputs.worker_security_group_id
  },
  {
    subnets = concat(dependency.networking.outputs.public_subnets)
    vpc_id  = dependency.networking.outputs.vpc_id
  },
)


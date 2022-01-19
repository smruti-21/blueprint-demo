## IaC - AWS DTAP environment  
   
 ### Introduction   
 This is an infrastructure as code repo to deploy AWS components in DTAP environment.  
   
 ### Prerequisite  
 - Get credentials of target AWS environment  
 - Install `tgwrapper` by using following command :  
   
 ```diff
 -$ pip3 install tgwrapper
 -$ pip3 install --upgrade tgwrapper # To upgrade
 ```
 ##### Usage:
 ```shell script
 usage: tgwrapper [-h] --action {init,plan,plan-all,apply,apply-all,destroy,output,hclfmt,state,import} [--args ARGS] [--config_dir CONFIG_DIR] [--config_template CONFIG_TEMPLATE]
                  --env ENV --profile PROFILE --region REGION [--tg_dir TG_DIR] [--verbosity VERBOSITY] [--version VERSION]
 
 Terragrunt wrapper to deploy the infrastructure in AWS
 
 optional arguments:
   -h, --help            show this help message and exit
   --action {init,plan,plan-all,apply,apply-all,destroy,output,hclfmt,state,import}, -a {init,plan,plan-all,apply,apply-all,destroy,output,hclfmt,state,import}
                         Terragrunt action.
   --args ARGS           Terraform extra args.
   --config_dir CONFIG_DIR, -d CONFIG_DIR
                         Name of config directory inside PROJECT_ROOT.
   --config_template CONFIG_TEMPLATE, -c CONFIG_TEMPLATE
                         Name of config template file inside config directory.
   --env ENV, -e ENV     Target environment.
   --profile PROFILE, -p PROFILE
                         AWS profile.
   --region REGION, -r REGION
                         AWS region.
   --tg_dir TG_DIR, -t TG_DIR
                         Name of terragrunt module directory inside PROJECT_ROOT.
   --verbosity VERBOSITY, -v VERBOSITY
                         Enable debug.
 
 Default PROJECT_ROOT is current directory, please set it appropriately where your config dir exists
 ```
 
 `tgwrap` documentation can be found here  - 
 https://github.com/smruti-21/mob-terragrunt-wrapper.git
      
   
 ### Steps to deploy  
   
 - Set the `PROJECT_ROOT`, by default it takes the current working directory.  
   
 ```diff 
 -$ export PROJECT_ROOT=<PROJECT_HOME_DIRECTORY>
 ```
 Example: 
 ```diff 
 -$ export PROJECT_ROOT=/Users/ssahoo/mobiquity/blueprint-dtap
 ```
     
 - Go to the specific directory where `terragrunt.hcl` file present   
 - Run the following command to plan, like wise you may apply or try with various arguments.
 
 ```diff 
 -$ tgwrapper -e <Environment Name> -r <AWS region> -p <AWS profile name> -a plan
 ```
 ```diff 
 -$ cd /Users/ssahoo/mobiquity/blueprint-dtap/terragrunt_modules/regional/vpc_matomo/networking 
 
 -$ export PROJECT_ROOT=/Users/ssahoo/mobiquity/blueprint-dtap
 
 -$ tgwrapper -e dev -r eu-west-1 -p kib-dev -a plan
 ```
### Whitelist of Mobiquity IPs can be found here:
[Mobiquity whitelist IPs list](https://aldawli.atlassian.net/wiki/spaces/KIB/pages/4442030156?atlOrigin=eyJpIjoiMDIwMWY1MmY0NTNhNDBkNTgxZTM2ZjY3YzcwMWUwYzEiLCJwIjoiYyJ9)

### Whitelist of Vendor IPs can be found here:
[Vendor whitelist IPs list](https://aldawli.atlassian.net/l/c/0zuZKcA3)

### Known issues:

* AWS auth error:
If you see following error during plan or apply : 

``` Error: Get "http://localhost/api/v1/namespaces/kube-system/configmaps/aws-auth": dial tcp [::1]:80: connect: connection refused ```

Please delete the auth from remote state and run the plan/apply again, ideally it should solve the issue.

```
tgwrapper -e <environment> -r eu-west-1 -p <aws profile> -a state --args "rm kubernetes_config_map.aws_auth[0]"
```

**Note**: You can list all the states by using following command - 
```
tgwrapper -e dev -r eu-west-1 -p temp_kib-dev -a state --args "list"
```
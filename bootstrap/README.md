Initialize the backend, it will create:
-- 
* State bucket with name `<AWS_account_number>_<AWS_region>>-tfstate`
* State lock dynamo db with name `dynamo_lock_table`

```shell
$ bash initialise.sh
Usage: initialise.sh [options]
Options:

    -a     Terraform action (eg. plan or apply)
    -e     Environment name (eg. dev)
    -p     AWS profile name (eg. default)
    -r     AWS region name  (eg. eu-west-1)
    -h     Help
 
 Example: 
 
 $ bash initialise.sh -a apply -e cicd -p kib-cicd -r eu-west-1
```

Note: There is an issue with creating s3 back-end because of chicken-egg problem.
Hence, we're following below steps to fix the issue, later we will fix this issue.


#### step 1:
  
After executing `initialise.sh`, copy local terraform state to the S3 bucket created by first execution.

```aws s3 cp terraform-cicd-eu-west-1.tfstate s3://197259779380-eu-west-1-tfstate/ --profile kib-cicd```

#### step 2:

Copy backend.temp to backend.tf
  
```cp backend.temp backend.tf```

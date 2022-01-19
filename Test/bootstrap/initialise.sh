#!/usr/bin/env bash

# Usage function
function usage() {
cat << EOF
Usage: $0 [options]
Options:

    -a     Terraform action (eg. apply)
    -e     Environment name (eg. dev)
    -p     AWS profile name (eg. default)
    -r     AWS region name  (eg. eu-west-1)
    -h     Help

EOF
exit 1
}

while getopts ":a:e:p:r:" opt; do
    case "${opt}" in
        a)
            ACTION=${OPTARG}
            ;;
        e)
            ENV=${OPTARG}
            ;;
        p)
            PROFILE=${OPTARG}
            ;;
        r)
            REGION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${ACTION}" ] || [ -z "${ENV}" ] || [ -z "${PROFILE}" ] || [ -z "${REGION}" ]; then
    usage
fi

BUCKET_PREFIX=$(aws sts get-caller-identity --query 'Account' --output text --profile "${PROFILE}")
TF_VAR_region=${REGION}
TF_VAR_tf_state_bucket=${BUCKET_PREFIX}-${REGION}-tfstate  # eg. State bucket name: 197259779380-eu-west-1-tfstate
TF_VAR_tf_state_table=dynamo_lock_table
TF_VAR_key=terraform-${ENV}-${REGION}.tfstate # eg. State file name: terraform-dev-eu-west-1.tfstate

TF_LOG=TRACE terraform init \
     -backend-config="bucket=$TF_VAR_tf_state_bucket" \
     -backend-config="dynamodb_table=$TF_VAR_tf_state_table" \
     -backend-config="region=$TF_VAR_region" \
     -backend-config="key=$TF_VAR_key" \
     -backend-config="profile=$PROFILE" \
     -backend=true \
     -force-copy \
     -get=true \
     -input=false

terraform "${ACTION}" --auto-approve \
-var region="${REGION}" \
-var aws_profile="${PROFILE}" \
-var dynamo_lock_table=dynamo_lock_table \
-state=terraform-"${ENV}"-"${REGION}".tfstate

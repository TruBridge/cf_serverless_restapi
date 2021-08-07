#!/bin/bash

source ./source_ci_default.sh

# Deploy Lambda to S3
result=$(aws s3 ls s3://${S3Bucket}/${Filepath}${Lambda} || echo "")
if [[ ${#result} -eq 0 ]] || [[ ${OverwriteVersion} == true ]]; then
  zip -j ${Lambda} lambda/*
  aws s3 cp ${Lambda} s3://${S3Bucket}/${Filepath} --sse aws:kms --sse-kms-key-id ${S3KMSID}
else
  echo "File already exists and will not be overriden."
fi

# Deploy Stack
aws cloudformation deploy --no-fail-on-empty-changeset --capabilities CAPABILITY_NAMED_IAM --template-file api-gateway.yml --stack-name ${CF_STACK_NAME} --parameter-overrides ${CF_PARAMETER_OVERRIDE} --tags "ApplicationName=$ApplicationName" "CostReference=$CostReference" "Creator=$Creator" "CustomerContactMail=$CustomerContactMail" "Environment=$Environment" "TicketReference=$TicketReference"
# Wait till Stack was created
aws cloudformation wait stack-create-complete --stack-name ${CF_STACK_NAME}
# Enable Stack protection so that it cannot be accidentally deleted
aws cloudformation update-termination-protection --stack-name ${CF_STACK_NAME} --enable-termination-protection

# Get Output for Gateway-ID from Stack
ApiGwId=$(aws cloudformation describe-stacks --stack-name ${CF_STACK_NAME} --query "Stacks[0].Outputs[?ExportName=='agw${ProjectShortName}${Environment}${ApplicationName}${ContinousNumber}-id'].OutputValue" --output text)
# Get Output for GatewayApiKey-ID from Stack
ApiGwKeyId=$(aws cloudformation describe-stacks --stack-name ${CF_STACK_NAME} --query "Stacks[0].Outputs[?ExportName=='agwkey${ProjectShortName}${Environment}${ApplicationName}${ContinousNumber}-id'].OutputValue" --output text)
# Get Key-Value by Key-ID
ApiGwApiKey=$(aws apigateway get-api-key --api-key ${ApiGwKeyId} --query "value" --include-value --output text)
# Build Gateway URL
ApiGwURL="https://${ApiGwId}-${VpcEndpointId}.execute-api.eu-central-1.amazonaws.com/${Environment}"

# Write URL to SSM so it can be queried by customers
aws ssm put-parameter --cli-input-json '{
  "Name":'\"/${ProjectShortName}/${Environment}/ssm/${ContinousNumber}/listparams/apiGwUrl\"',
  "Value":'\"${ApiGwURL}\"',
  "Type":"String"
}' --overwrite

aws ssm put-parameter --key-id ${CustomerSSMKMSID} --cli-input-json '{
  "Name":'\"/${ProjectShortName}/${Environment}/ssm/${ContinousNumber}/listparams/apiGwApiKey\"',
  "Value":'\"${ApiGwApiKey}\"',
  "Type":"SecureString"
}' --overwrite
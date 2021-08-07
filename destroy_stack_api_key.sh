#!/bin/bash

source ./source_ci_default.sh

# Update termination protection so that it can be deleted again
aws cloudformation update-termination-protection --stack-name ${CF_STACK_NAME} --no-enable-termination-protection #DisableTerminationProtection for CloudFormationStack
# Delete stack
aws cloudformation delete-stack --stack-name ${CF_STACK_NAME}
# Wait till stack deletion is done
aws cloudformation wait stack-delete-complete --stack-name ${CF_STACK_NAME}
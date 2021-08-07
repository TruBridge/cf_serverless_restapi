#!/bin/bash

# export all variables to session ignoring lines containing #
export $(cat default.properties | grep -v '#')
# export stackname
export CF_STACK_NAME=$(echo "cfs-${ProjectShortName}-${Environment}-${ApplicationName}-${ContinousNumber}" | tr '[:upper:]' '[:lower:]')
# export all variables to session ignoring lines containing # for deployment
export CF_PARAMETER_OVERRIDE=$(cat default.properties | grep -v '#' | tr ' ' '-' | tr '\r\n' ' ') ## replace spaces with dashes and newlines with spaces

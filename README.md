# ci-cd-api-gateway

This cloudformation template is used to build a RestApi gateway including a lambda to load customers SSM parameters.

## Buildprocess

The pipeline automatically builds a zip from the required sources and loads the artifact onto the specified bucket.

## Specifics

### Api Gateway

#### Api Key

The RestApi gateway is set up together with the ApiKey and usage plan. Authorisation is therefore carried out via this key. IAM Auth was explicitly omitted, as Curl, for example, is not able to attract the instance profile.
Both ApiKey and the URL of the RestApi gateway are saved in the specific customer area in the SSM by the pipeline:<br>
`/${ProjectShortName}/customer/${Environment}/ssm/${ContinousNumber}/listparams/apiGwUrl`<br>
`/${ProjectShortName}/customer/${Environment}/ssm/${ContinousNumber}/listparams/apiGwApiKey`

#### IAM Auth

Authorisation is through instance profile. You need to use a tool that provides instance profile capabilities.<br>
The URL of the RestApi gateway is saved in the specific customer area in the SSM by the pipeline:<br>
`/${ProjectShortName}/customer/${Environment}/ssm/${ContinousNumber}/listparams/apiGwUrl`

### Lambda

The Lambda currently runs on Python3.8 and uses Boto to send a describe_parameters. It receives the authorisation through an instance profile, which is set by the pipeline. The result is returned in the form of a list, e.g.:<br>
`"['/{customer}/{environment}/ssm/01/listparams/apiGwApiKey', '/{customer}/{environment}/ssm/01/listparams/apiGwUrl']"`<br>
The restriction is automatically made to the specific customer area and the environment with which the pipeline was started.

## Usage

### Api Key

You can call the RestApi as follows:<br>
`curl -X POST -H "Content-Type: application/json" -H "x-api-key: {apiGwApiKey}" {apiGwUrl}`

### IAM Auth

First: attach a valid IAM role to an EC2 instance.<br>
Second: Use following code on the EC2 instance:<br>
```
import requests
import boto3
from aws_requests_auth.aws_auth import AWSRequestsAuth

destinationhost=input("Please enter the destinationhost: ")
stage=input("Please enter the stage: ")
region=input("Please enter the region: ")

boto3.setup_default_session(region_name=region)
session = boto3.Session()
credentials = session.get_credentials()

auth = AWSRequestsAuth(aws_access_key=credentials.access_key,
aws_secret_access_key=credentials.secret_key,
aws_token=credentials.token,
aws_host=str(destinationhost),
aws_region=str(region),
aws_service='execute-api')

print(requests.request('POST', 'https://' + str(destinationhost) + '/' + str(stage) + '/', auth=auth).text)
```
and execute the code by:<br>
`python {filename}`
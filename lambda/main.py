import boto3
import os
import traceback

client = boto3.client('ssm')
customer = os.environ['customer']
env = os.environ['environment']


def get_resources_from(ssm_details):
    results = ssm_details['Parameters']
    resources = [result['Name'] for result in results]
    next_token = ssm_details.get('NextToken', None)
    return resources, next_token


def list_ssm_parameters():
    resources = []
    try:
        next_token = ''
        while next_token is not None:
            ssm_details = client.describe_parameters(
                ParameterFilters=[{"Key": "Name", "Option": "BeginsWith", "Values": ["/" + customer + "/" + env]}],
                MaxResults=50,
                NextToken=next_token)
            current_batch, next_token = get_resources_from(ssm_details)
            resources += current_batch
    except:
        print("Encountered an error loading information from SSM.")
        traceback.print_exc()
    finally:
        return str(resources)


def list(event, context):
    return list_ssm_parameters()

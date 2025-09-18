import os, boto3
from botocore.exceptions import ClientError
ssm=boto3.client('ssm'); BREAKER_PARAM=os.getenv('BREAKER_PARAM','/sitegen/circuit_breaker/state')
def lambda_handler(event,ctx):
    try:
        state=ssm.get_parameter(Name=BREAKER_PARAM)['Parameter']['Value']
    except ClientError:
        state='closed'
    return {'state':state}

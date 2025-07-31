import json
import boto3
import os
import logging

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    sfn = boto3.client('stepfunctions')
    state_machine_arn = os.environ['STATE_MACHINE_ARN']
    for record in event['Records']:
        try:
            body = json.loads(record['body'])
            response = sfn.start_execution(
                stateMachineArn=state_machine_arn,
                input=json.dumps(body)
            )
            logging.info(f"Execução iniciada: {response['executionArn']}")
        except Exception as e:
            logging.exception("Erro ao invocar Step Function")
    return {"statusCode": 200, "body": json.dumps({"message": "Mensagens processadas"})}

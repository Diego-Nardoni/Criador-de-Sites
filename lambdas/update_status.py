import json
import boto3
import os
import logging

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        job_id = body.get('jobId')
        status = body.get('status', 'completed')
        table = os.environ.get('STATUS_TABLE')
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(table)
        table.update_item(
            Key={'jobId': job_id},
            UpdateExpression='SET #s = :s',
            ExpressionAttributeNames={'#s': 'status'},
            ExpressionAttributeValues={':s': status}
        )
        return {"statusCode": 200, "body": json.dumps({"message": "Status atualizado"})}
    except Exception as e:
        logging.exception("Erro ao atualizar status no DynamoDB")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

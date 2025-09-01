import json
import boto3
import os
import logging

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    sqs = boto3.client('sqs')
    status_table = os.environ.get('STATUS_TABLE')
    user_table = os.environ.get('USER_TABLE')
    premium_queue_url = os.environ.get('PREMIUM_QUEUE_URL')
    free_queue_url = os.environ.get('FREE_QUEUE_URL')
    # Suporte a múltiplos planos
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        user_id = body.get('user_id')
        plan_type = body.get('plan_type', 'free')
        job_id = body.get('jobId')
        # Cria status inicial no DynamoDB (opcional, pode ser expandido)
        if status_table and job_id:
            dynamodb = boto3.resource('dynamodb')
            table = dynamodb.Table(status_table)
            table.put_item(Item={
                'jobId': job_id,
                'userId': user_id,
                'planType': plan_type,
                'status': 'queued'
            })
        # Enfileira na fila correta
        queue_url = premium_queue_url if plan_type == 'premium' else free_queue_url
        sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(body))
        return {"statusCode": 200, "body": json.dumps({"message": "Enfileirado com sucesso", "jobId": job_id})}
    except Exception as e:
        logging.exception("Erro ao enfileirar mensagem")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

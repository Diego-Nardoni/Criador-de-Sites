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
        theme = body.get('site_theme')
        bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
        prompt = f"Crie um site sobre {theme} conforme requisitos."
        response = bedrock.invoke_model(
            modelId=os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0'),
            contentType='application/json',
            accept='application/json',
            body=json.dumps({"prompt": prompt})
        )
        html = json.loads(response['body'].read())['result']
        return {"statusCode": 200, "body": json.dumps({"html": html})}
    except Exception as e:
        logging.exception("Erro ao gerar HTML")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

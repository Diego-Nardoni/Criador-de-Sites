import json
import boto3
import os
import logging
import aws_xray_sdk
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Configurar X-Ray
aws_xray_sdk.global_sdk_config.set_sdk_enabled(True)
xray_recorder.configure(service='GenerateHTMLLambda')
patch_all()

import time, random
import botocore

def bedrock_request_with_retry(client, **kwargs):
    for attempt in range(4):
        try:
            return bedrock_request_with_retry(client, **kwargs)
        except botocore.exceptions.ClientError as e:
            code = e.response.get('Error', {}).get('Code', '')
            if code in ('ThrottlingException','ServiceUnavailableException','InternalServerException'):
                sleep = min(2*(2**attempt) + random.random(), 10)
                time.sleep(sleep)
                continue
            raise
    raise RuntimeError("Bedrock unavailable after retries")


def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    
    # Adicionar subsegmento do X-Ray
    subsegment = xray_recorder.begin_subsegment('generate_html_process')
    
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        theme = body.get('site_theme')
        
        # Adicionar metadados ao subsegmento
        subsegment.put_annotation('theme', theme)
        subsegment.put_metadata('input_body', body)
        
        # Obter o template de prompt das variáveis de ambiente ou usar um padrão
        prompt_template = os.environ.get('HTML_PROMPT_TEMPLATE', "Crie um site sobre [TEMA] conforme requisitos.")
        prompt = prompt_template.replace('[TEMA]', theme)
        
        # Configurar cliente Bedrock
        bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('REGION', 'us-east-1'))
        model_id = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
        
        # Formato correto para Claude 3 no Bedrock
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        }
        
        logging.info(f"Invocando modelo Bedrock: {model_id}")
        response = bedrock.invoke_model(
            modelId=model_id,
            contentType='application/json',
            accept='application/json',
            body=json.dumps(request_body)
        )
        
        # Processar resposta
        response_body = json.loads(response['body'].read())
        html = response_body['content'][0]['text']
        
        logging.info("HTML gerado com sucesso")
        # Finalizar subsegmento com sucesso
        xray_recorder.end_subsegment()
        return {"statusCode": 200, "body": json.dumps({"html": html})}
    except Exception as e:
        # Marcar subsegmento como erro
        subsegment.add_exception(e)
        xray_recorder.end_subsegment()
        logging.exception("Erro ao gerar HTML")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

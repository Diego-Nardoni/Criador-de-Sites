import json
import boto3
import os
import logging
import uuid

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    try:
        # Obter dados do evento
        logging.info(f"Evento recebido: {event}")
        
        # Verificar se o evento veio de uma Step Function ou API Gateway
        if isinstance(event, dict) and 'body' in event:
            body = event.get('body')
            if isinstance(body, str):
                body = json.loads(body)
        else:
            body = event
            
        user_id = body.get('user_id', str(uuid.uuid4()))
        html = body.get('html')
        
        if not html:
            logging.error("HTML não encontrado no evento")
            return {"statusCode": 400, "body": json.dumps({"error": "HTML não fornecido"})}
        
        # Obter nome do bucket de saída da variável de ambiente
        bucket = os.environ.get('OUTPUT_BUCKET', 'criador-de-sites-output-bucket')
        region = os.environ.get('REGION', 'us-east-1')
        
        # Criar cliente S3
        s3 = boto3.client('s3', region_name=region)
        
        # Definir caminho do arquivo
        key = f"{user_id}/index.html"
        
        # Salvar HTML no S3
        logging.info(f"Salvando HTML no bucket {bucket}, chave {key}")
        s3.put_object(
            Bucket=bucket, 
            Key=key, 
            Body=html, 
            ContentType='text/html',
            CacheControl='max-age=3600'
        )
        
        # Gerar URL do site
        url = f"https://{bucket}.s3.{region}.amazonaws.com/{key}"
        
        logging.info(f"Site salvo com sucesso: {url}")
        return {
            "statusCode": 200, 
            "body": json.dumps({
                "site_url": url,
                "s3_key": key,
                "user_id": user_id
            })
        }
    except Exception as e:
        logging.exception("Erro ao salvar site no S3")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

import json
import boto3
import os
import logging
import uuid

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    
    # Configurar região
    region = os.environ.get('REGION', 'us-east-1')
    
    # Inicializar clientes
    sqs = boto3.client('sqs', region_name=region)
    
    # Obter configurações das variáveis de ambiente ou usar valores padrão
    status_table = os.environ.get('STATUS_TABLE', 'site_gen_status')
    user_table = os.environ.get('USER_TABLE', 'user_profiles')
    premium_queue_url = os.environ.get('PREMIUM_QUEUE_URL')
    free_queue_url = os.environ.get('FREE_QUEUE_URL')
    
    # Se as URLs das filas não estiverem definidas, tentar obter pelos nomes
    if not premium_queue_url:
        try:
            premium_queue_url = sqs.get_queue_url(QueueName='GeradorDeSites-prod-premium-queue')['QueueUrl']
        except Exception as e:
            logging.warning(f"Não foi possível obter URL da fila premium: {e}")
    
    if not free_queue_url:
        try:
            free_queue_url = sqs.get_queue_url(QueueName='GeradorDeSites-prod-free-queue')['QueueUrl']
        except Exception as e:
            logging.warning(f"Não foi possível obter URL da fila free: {e}")
    
    # Processar a requisição
    try:
        # Extrair corpo da requisição
        logging.info(f"Evento recebido: {event}")
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        
        # Extrair parâmetros
        user_id = body.get('user_id', str(uuid.uuid4()))
        
        # Determinar o tipo de plano com base na chave de API
        api_key = event.get('headers', {}).get('x-api-key')
        
        # Verificar se a chave de API corresponde a um plano premium
        # Nota: Em produção, isso seria verificado contra um banco de dados ou serviço
        plan_type = 'free'  # Padrão para free
        
        # Verificar se a chave de API está presente e determinar o plano
        if api_key:
            # Aqui você pode implementar a lógica para verificar a chave de API
            # Por exemplo, consultando um banco de dados ou serviço
            # Por enquanto, vamos usar uma lógica simples baseada no parâmetro do corpo
            if body.get('plan_type') == 'premium':
                plan_type = 'premium'
        
        job_id = body.get('jobId', str(uuid.uuid4()))
        site_theme = body.get('site_theme')
        
        if not site_theme:
            return {
                "statusCode": 400, 
                "body": json.dumps({
                    "error": "Parâmetro 'site_theme' é obrigatório"
                })
            }
        
        # Preparar mensagem para a fila
        message = {
            "jobId": job_id,
            "userId": user_id,
            "planType": plan_type,
            "site_theme": site_theme,
            "timestamp": str(boto3.utils.datetime.datetime.now())
        }
        
        # Criar status inicial no DynamoDB
        if status_table:
            try:
                dynamodb = boto3.resource('dynamodb', region_name=region)
                table = dynamodb.Table(status_table)
                table.put_item(Item={
                    'jobId': job_id,
                    'userId': user_id,
                    'planType': plan_type,
                    'status': 'queued',
                    'site_theme': site_theme,
                    'timestamp': message["timestamp"]
                })
                logging.info(f"Status inicial criado no DynamoDB para jobId: {job_id}")
            except Exception as e:
                logging.error(f"Erro ao criar status no DynamoDB: {e}")
        
        # Enfileirar na fila correta
        queue_url = premium_queue_url if plan_type == 'premium' else free_queue_url
        
        if not queue_url:
            return {
                "statusCode": 500, 
                "body": json.dumps({
                    "error": f"URL da fila {plan_type} não configurada"
                })
            }
        
        sqs.send_message(
            QueueUrl=queue_url, 
            MessageBody=json.dumps(message)
        )
        
        logging.info(f"Mensagem enfileirada com sucesso na fila {plan_type}")
        return {
            "statusCode": 200, 
            "body": json.dumps({
                "message": "Solicitação enfileirada com sucesso", 
                "jobId": job_id,
                "userId": user_id,
                "planType": plan_type
            })
        }
    except Exception as e:
        logging.exception("Erro ao processar requisição")
        return {
            "statusCode": 500, 
            "body": json.dumps({
                "error": str(e)
            })
        }

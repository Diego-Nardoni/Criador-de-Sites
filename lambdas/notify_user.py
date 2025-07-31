import json
import logging

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        # Exemplo: enviar e-mail, push, etc. Aqui apenas loga.
        logging.info(f"Notificando usuário: {body.get('user_id')}")
        return {"statusCode": 200, "body": json.dumps({"message": "Usuário notificado"})}
    except Exception as e:
        logging.exception("Erro ao notificar usuário")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

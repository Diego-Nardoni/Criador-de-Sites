import json
import logging

def lambda_handler(event, context):
    logging.basicConfig(level=logging.INFO)
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        theme = body.get('site_theme')
        image = body.get('context_image')
        if not theme:
            return {"statusCode": 400, "body": json.dumps({"error": "Tema obrigatório"})}
        # Exemplo de validação de imagem (opcional)
        if image and not image.startswith('data:image/'):
            return {"statusCode": 400, "body": json.dumps({"error": "Formato de imagem inválido"})}
        return {"statusCode": 200, "body": json.dumps({"message": "Input válido"})}
    except Exception as e:
        logging.exception("Erro na validação de input")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

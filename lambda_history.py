import boto3
import json
import os

def lambda_handler(event, context):
    # Extrai user_id do JWT Cognito (API Gateway authorizer)
    claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
    user_id = claims.get('sub')
    if not user_id:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Usuário não autenticado'})
        }
    bucket_name = os.environ['BUCKET_NAME']
    s3 = boto3.client('s3')
    history_key = f"history/{user_id}.json"
    try:
        resp = s3.get_object(Bucket=bucket_name, Key=history_key)
        history = json.loads(resp['Body'].read())
    except Exception:
        history = []
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(history)
    }

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
        user_id = body.get('user_id')
        html = body.get('html')
        bucket = os.environ.get('OUTPUT_BUCKET')
        s3 = boto3.client('s3')
        key = f"{user_id}/index.html"
        s3.put_object(Bucket=bucket, Key=key, Body=html, ContentType='text/html')
        url = f"https://{bucket}.s3.amazonaws.com/{key}"
        return {"statusCode": 200, "body": json.dumps({"site_url": url})}
    except Exception as e:
        logging.exception("Erro ao salvar site no S3")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

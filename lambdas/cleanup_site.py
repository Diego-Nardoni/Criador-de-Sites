import os, boto3
s3=boto3.client('s3')
def lambda_handler(event,ctx):
    key=(event.get('key') or event.get('s3_key') or '')
    bucket=os.environ.get('OUTPUT_BUCKET')
    if bucket and key:
        try:
            s3.delete_object(Bucket=bucket, Key=key)
            return {'deleted':True,'key':key}
        except Exception as e:
            return {'deleted':False,'error':str(e)}
    return {'deleted':False,'error':'missing bucket/key'}

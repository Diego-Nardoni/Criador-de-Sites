import os, json, boto3
ddb=boto3.resource('dynamodb'); table=ddb.Table(os.environ.get('STATUS_TABLE'))
def lambda_handler(event,ctx):
    job_id=event.get('pathParameters',{}).get('id')
    if not job_id: return {'statusCode':400,'body':json.dumps({'error':'missing id'})}
    r=table.get_item(Key={'jobId':job_id}); item=r.get('Item')
    if not item: return {'statusCode':404,'body':json.dumps({'error':'not found'})}
    return {'statusCode':200,'body':json.dumps(item, default=str)}

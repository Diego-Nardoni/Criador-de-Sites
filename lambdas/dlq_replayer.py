import os, boto3, hashlib
sqs=boto3.client('sqs'); ddb=boto3.resource('dynamodb')
DLQ_URL=os.environ.get('DLQ_URL'); TARGET_URL=os.environ.get('TARGET_URL'); QUARANTINE_TABLE=os.environ.get('QUARANTINE_TABLE','')
def _poison(body):
    try:
        h=hashlib.sha256(body.encode()).hexdigest()
        if QUARANTINE_TABLE:
            t=ddb.Table(QUARANTINE_TABLE); r=t.get_item(Key={'hash':h})
            return 'Item' in r
    except: pass
    return False
def lambda_handler(event,ctx):
    r=sqs.receive_message(QueueUrl=DLQ_URL, MaxNumberOfMessages=5, WaitTimeSeconds=1)
    msgs=r.get('Messages',[]); c=0
    for m in msgs:
        body=m['Body']
        if not _poison(body):
            sqs.send_message(QueueUrl=TARGET_URL, MessageBody=body)
        sqs.delete_message(QueueUrl=DLQ_URL, ReceiptHandle=m['ReceiptHandle']); c+=1
    return {'replayed':c}

import os, json, time, hashlib, boto3, logging
from botocore.exceptions import ClientError
ssm=boto3.client('ssm'); sfn=boto3.client('stepfunctions'); ddb=boto3.resource('dynamodb'); cw=boto3.client('cloudwatch'); sqs=boto3.client('sqs')
BREAKER_PARAM=os.getenv('BREAKER_PARAM','/sitegen/circuit_breaker/state')
RETRY_AFTER=os.getenv('RETRY_AFTER','60')
STATUS_TABLE=os.getenv('STATUS_TABLE')
QUEUE_URL_FREE=os.getenv('QUEUE_URL_FREE'); QUEUE_URL_PREMIUM=os.getenv('QUEUE_URL_PREMIUM')
USE_SQS_UNDER_LOAD=os.getenv('USE_SQS_UNDER_LOAD','true').lower()=='true'
LOAD_ALARM_NAMES=[n.strip() for n in os.getenv('LOAD_ALARM_NAMES','').split(',') if n.strip()]
PREMIUM_HEADER=os.getenv('PREMIUM_HEADER','x-plan')
CORRELATION_HEADER=os.getenv('CORRELATION_HEADER','x-correlation-id')
def _alarm_state():
    if not LOAD_ALARM_NAMES: return "OK"
    try:
        resp=cw.describe_alarms(AlarmNames=LOAD_ALARM_NAMES)
        for a in resp.get('MetricAlarms',[]): 
            if a.get('StateValue') in ('ALARM','INSUFFICIENT_DATA'): return a.get('StateValue')
    except Exception as e:
        logging.warning("alarms error: %s",e)
    return "OK"
def lambda_handler(event,ctx):
    logging.getLogger().setLevel(logging.INFO)
    headers=event.get('headers') or {}
    corr=headers.get(CORRELATION_HEADER) or str(int(time.time()*1000))
    plan=(headers.get(PREMIUM_HEADER) or "free").lower()
    try:
        state=ssm.get_parameter(Name=BREAKER_PARAM)['Parameter']['Value']
    except ClientError:
        state='closed'
    if state=='open':
        return {'statusCode':503,'headers':{'Retry-After':RETRY_AFTER,CORRELATION_HEADER:corr},'body':json.dumps({'error':'circuit_open'})}
    body=event.get('body') or "{}"
    if isinstance(body,str):
        try: body=json.loads(body)
        except: body={}
    user_id=body.get('user_id','anon')
    idem=headers.get('Idempotency-Key')
    if idem:
        job_id=hashlib.sha256((idem+'|'+user_id).encode()).hexdigest()[:32]
    else:
        job_id=str(int(time.time()*1000))
    table=ddb.Table(STATUS_TABLE)
    try:
        table.put_item(Item={'jobId':job_id,'status':'RECEIVED','userId':user_id,'createdAt':int(time.time()),'correlationId':corr,'idempotencyKey':idem or ''},
                       ConditionExpression="attribute_not_exists(jobId)")
    except ClientError as e:
        if e.response['Error']['Code']!='ConditionalCheckFailedException': raise
    if USE_SQS_UNDER_LOAD and _alarm_state() in ('ALARM','INSUFFICIENT_DATA'):
        q=QUEUE_URL_PREMIUM if plan=='premium' and QUEUE_URL_PREMIUM else QUEUE_URL_FREE
        sqs.send_message(QueueUrl=q, MessageBody=json.dumps({**body,'jobId':job_id,'correlationId':corr}))
        return {'statusCode':202,'headers':{CORRELATION_HEADER:corr},'body':json.dumps({'jobId':job_id,'queued':True})}
    sfn.start_execution(stateMachineArn=os.environ['SFN_ARN'], input=json.dumps({**body,'jobId':job_id,'correlationId':corr}))
    return {'statusCode':202,'headers':{CORRELATION_HEADER:corr},'body':json.dumps({'jobId':job_id,'queued':False})}

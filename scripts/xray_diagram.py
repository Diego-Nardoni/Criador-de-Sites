from diagrams import Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.integration import APIGateway
from diagrams.aws.analytics import Elasticsearch
from diagrams.custom import Custom

# Usar um ícone personalizado para X-Ray
with Diagram('AWS X-Ray Tracing Architecture', show=False, direction='TB'):
    xray = Custom('AWS X-Ray', './static/xray-icon.png')
    sampling_rule = Elasticsearch('Sampling Rule')
    trace_group = Elasticsearch('Trace Group')
    
    api_gw = APIGateway('API Gateway')
    lambda_func = Lambda('Generate HTML Lambda')
    
    api_gw >> Edge(label='Incoming Request', color='blue') >> lambda_func
    lambda_func >> Edge(label='Create Trace', color='green') >> xray
    xray >> Edge(label='Apply Rules', color='orange') >> sampling_rule
    xray >> Edge(label='Group Traces', color='purple') >> trace_group

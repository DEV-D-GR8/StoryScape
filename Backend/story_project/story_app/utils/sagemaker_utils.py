import json
import boto3
from django.conf import settings

# Initialize AWS SageMaker Runtime client
sagemaker_client = boto3.client(
    'sagemaker-runtime',
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    region_name=settings.AWS_REGION
)

SAGEMAKER_ENDPOINT_NAME = settings.SAGEMAKER_ENDPOINT_NAME

def call_sagemaker_llm(prompt):
    try:
        response = sagemaker_client.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps({'prompt': prompt})
        )
        response_body = response['Body'].read()
        response_text = json.loads(response_body.decode('utf-8'))['generated_text']
        return response_text
    except Exception as e:
        raise Exception(f"SageMaker endpoint invocation failed: {str(e)}")

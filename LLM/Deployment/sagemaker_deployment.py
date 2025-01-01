import os
import time
import boto3

# Initialize SageMaker client with the specified region
sagemaker = boto3.client('sagemaker', region_name=os.getenv('AWS_REGION'))

# Retrieve sensitive information from environment variables
ecr_image = os.getenv('ECR_IMAGE_URL')  
model_data_url = os.getenv('S3_MODEL_DATA_URL')  
role_arn = os.getenv('SAGEMAKER_EXECUTION_ROLE_ARN')  

if not all([ecr_image, model_data_url, role_arn]):
    raise ValueError("Ensure ECR_IMAGE_URL, S3_MODEL_DATA_URL, and SAGEMAKER_EXECUTION_ROLE_ARN are set in environment variables")

# Define model, endpoint config, and endpoint names
model_name = os.getenv('llama-sagemaker-model')
endpoint_config_name = os.getenv('llama-endpoint-config')
endpoint_name = os.getenv('llama-endpoint')

# Define the primary container
primary_container = {
    'Image': ecr_image,
    'ModelDataUrl': model_data_url,
    'Environment': {}
}

# Step 1: Create the SageMaker Model
print("Creating the SageMaker Model...")
response = sagemaker.create_model(
    ModelName=model_name,
    PrimaryContainer=primary_container,
    ExecutionRoleArn=role_arn
)
print(f"Model creation initiated: {response['ModelArn']}")

# Step 2: Create Endpoint Configuration
print("Creating the Endpoint Configuration...")
response = sagemaker.create_endpoint_config(
    EndpointConfigName=endpoint_config_name,
    ProductionVariants=[
        {
            'VariantName': 'AllTraffic',
            'ModelName': model_name,
            'InitialInstanceCount': 1,
            'InstanceType': 'ml.g4dn.xlarge',  
            'InitialVariantWeight': 1
        },
    ]
)
print(f"Endpoint configuration created: {response['EndpointConfigArn']}")

# Step 3: Deploy the Endpoint
print("Deploying the Endpoint...")
response = sagemaker.create_endpoint(
    EndpointName=endpoint_name,
    EndpointConfigName=endpoint_config_name
)
print(f"Endpoint creation initiated: {response['EndpointArn']}")

# Step 4: Wait for the Endpoint to be in service
def wait_for_endpoint(endpoint_name):
    print("Waiting for the endpoint to be InService...")
    while True:
        response = sagemaker.describe_endpoint(EndpointName=endpoint_name)
        status = response['EndpointStatus']
        print(f'Endpoint status: {status}')
        if status == 'InService':
            print("Endpoint is now InService.")
            break
        elif status == 'Failed':
            raise Exception('Endpoint creation failed')
        time.sleep(30)

wait_for_endpoint(endpoint_name)

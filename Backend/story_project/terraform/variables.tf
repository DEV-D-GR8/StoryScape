# variables.tf

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Elastic Beanstalk Application Name"
  type        = string
  default     = "story-django-app"
}

variable "env_name" {
  description = "Elastic Beanstalk Environment Name"
  type        = string
  default     = "story-django-env"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "sagemaker_endpoint_name" {
  description = "SageMaker Endpoint Name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 Bucket Name"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI Secret Key"
  type        = string
}

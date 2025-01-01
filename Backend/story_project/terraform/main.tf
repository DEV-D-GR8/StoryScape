# main.tf

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Elastic Beanstalk Application for Django Backend"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.app_name}-instance-profile"

  
}

resource "aws_iam_role" "iam_role" {
  name = "${var.app_name}-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.9 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_ACCESS_KEY_ID"
    value     = var.aws_access_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_SECRET_ACCESS_KEY"
    value     = var.aws_secret_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = var.aws_region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SAGEMAKER_ENDPOINT_NAME"
    value     = var.sagemaker_endpoint_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_BUCKET_NAME"
    value     = var.s3_bucket_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OPENAI_API_KEY"
    value     = var.openai_api_key
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }
}

resource "null_resource" "deploy_app" {
  provisioner "local-exec" {
    command = "eb deploy ${aws_elastic_beanstalk_environment.env.name}"
  }
}

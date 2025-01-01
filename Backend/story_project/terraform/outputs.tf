# outputs.tf

output "application_name" {
  value = aws_elastic_beanstalk_application.app.name
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.env.name
}

output "endpoint_url" {
  value = aws_elastic_beanstalk_environment.env.endpoint_url
}

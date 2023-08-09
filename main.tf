# terraform/main.tf

# Configure the AWS provider
provider "aws" {
  region = "us-east-1" 
}

# Create a Docker image 
data "docker_registry_image" "nginx" {
  name = "nginx:alpine"
}

# Create a Lambda function 
resource "aws_lambda_function" "nginx" {
  function_name = "nginx"

  # Use the docker image 
  image_uri = data.docker_registry_image.nginx.name

  package_type = "Image"

  role = aws_iam_role.lambda.arn
}

# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = "lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
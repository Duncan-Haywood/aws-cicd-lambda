# terraform/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
#   host = "unix:///var/run/docker.sock"
}

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

# API Gateway REST API
resource "aws_api_gateway_rest_api" "nginx" {
  name = "nginx"
}

# API Gateway resource
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.nginx.id
  parent_id   = aws_api_gateway_rest_api.nginx.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway method
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.nginx.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integrate method with Lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.nginx.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nginx.invoke_arn
}

# Deploy API
resource "aws_api_gateway_deployment" "nginx" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.nginx.id
  stage_name  = "test"
}

# Create usage plan
resource "aws_api_gateway_usage_plan" "nginx" {
  name = "nginx"

  api_stages {
    api_id = aws_api_gateway_rest_api.nginx.id
    stage  = aws_api_gateway_deployment.nginx.stage_name
  }
}

output "api_url" {
  value = "${aws_api_gateway_deployment.nginx.invoke_url}/{aws_api_gateway_deployment.nginx.stage_name}"
}
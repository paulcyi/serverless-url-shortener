terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# DynamoDB table for URL mappings
resource "aws_dynamodb_table" "urls" {
  name           = "urls"
  billing_mode   = "PAY_PER_REQUEST" # Serverless, cost-effective
  hash_key       = "short_code"
  attribute {
    name = "short_code"
    type = "S" # String for short codes
  }
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach basic Lambda execution policy (logs to CloudWatch)
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for DynamoDB access
resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "dynamodb_access"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
      Resource = aws_dynamodb_table.urls.arn
    }]
  })
}

# Lambda function: Shorten URL
resource "aws_lambda_function" "shorten" {
  filename         = "../lambda/shorten.zip"
  function_name    = "shorten_url"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "shorten.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("../lambda/shorten.zip")
}

# Lambda function: Redirect URL
resource "aws_lambda_function" "redirect" {
  filename         = "../lambda/redirect.zip"
  function_name    = "redirect_url"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "redirect.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("../lambda/redirect.zip")
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "url_shortener_api" {
  name        = "UrlShortenerAPI"
  description = "API for URL Shortener"
}

# Resource: /shorten
resource "aws_api_gateway_resource" "shorten" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  parent_id   = aws_api_gateway_rest_api.url_shortener_api.root_resource_id
  path_part   = "shorten"
}

# Resource: /redirect
resource "aws_api_gateway_resource" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  parent_id   = aws_api_gateway_rest_api.url_shortener_api.root_resource_id
  path_part   = "redirect"
}

# Resource: /redirect/{code}
resource "aws_api_gateway_resource" "redirect_code" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  parent_id   = aws_api_gateway_resource.redirect.id
  path_part   = "{code}"
}

# Method: POST /shorten
resource "aws_api_gateway_method" "shorten_post" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id   = aws_api_gateway_resource.shorten.id
  http_method   = "POST"
  authorization = "NONE"
}

# Method: GET /redirect/{code}
resource "aws_api_gateway_method" "redirect_get" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id   = aws_api_gateway_resource.redirect_code.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration: /shorten -> shorten_url Lambda
resource "aws_api_gateway_integration" "shorten_integration" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id             = aws_api_gateway_resource.shorten.id
  http_method             = aws_api_gateway_method.shorten_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.shorten.invoke_arn
}

# Integration: /redirect/{code} -> redirect_url Lambda
resource "aws_api_gateway_integration" "redirect_integration" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id             = aws_api_gateway_resource.redirect_code.id
  http_method             = aws_api_gateway_method.redirect_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redirect.invoke_arn
}

# Lambda Permissions for API Gateway to Invoke
resource "aws_lambda_permission" "api_gateway_shorten" {
  statement_id  = "AllowExecutionFromAPIGatewayShorten"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shorten.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.url_shortener_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_redirect" {
  statement_id  = "AllowExecutionFromAPIGatewayRedirect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.url_shortener_api.execution_arn}/prod/GET/redirect/*"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "url_shortener_deployment" {
  depends_on = [
    aws_api_gateway_integration.shorten_integration,
    aws_api_gateway_integration.redirect_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.url_shortener_deployment.id
  depends_on    = [aws_api_gateway_deployment.url_shortener_deployment]
  lifecycle {
    create_before_destroy = true
  }
}

# Update the output to use the new stage
output "api_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/shorten"
}

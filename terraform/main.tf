provider "aws" {
  region = "us-east-1"
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

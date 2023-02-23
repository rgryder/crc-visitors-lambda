terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  backend "remote" {
    organization = "gryder-io"
    workspaces {
      name = "crc-terraform"
    }
  }
}

data "archive_file" "crc_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}


resource "aws_dynamodb_table" "crc_dynamo" {
  name           = "CloudResume"
  hash_key       = "Name"
  read_capacity  = 10
  write_capacity = 10
  
  attribute {
    name = "Name"
    type = "S"
  }
  
  attribute {
    name = "Value"
    type = "N"
  }
}

resource "aws_iam_role" "crc_lambda_dynamodb" {
  name = "CRCLambdaDynamoDBRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "crc_lambda_dynamodb" {
  name = "CRCLambdaDynamoDBPolicy"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "dynamodb:UpdateItem",
            "Resource": aws_dynamodb_table.crc_dynamo.arn
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment" {
  role       = aws_iam_role.crc_lambda_dynamodb.name
  policy_arn = aws_iam_policy.crc_lambda_dynamodb.arn
}

resource "aws_lambda_function" "crc_visitor_count" {
  filename      = "lambda_function_payload.zip"
  function_name = "CRCVisitorCount"
  role          = aws_iam_role.crc_lambda_dynamodb.arn
  timeout       = 3

  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}






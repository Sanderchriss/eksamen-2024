

# Referanse til eksisterende S3-bucket
data "aws_s3_bucket" "existing_bucket" {
  bucket = "pgr301-couch-explorers" # Endre til navnet på den eksisterende bøtten
}

# Opprett SQS-køen
resource "aws_sqs_queue" "lambda_queue" {
  name = "lambda_sqs_queue"
}

# IAM-rolle for Lambda-funksjonen
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

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

resource "aws_iam_policy" "lambda_policy16" {
  name = "lambda_policy16"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Gi tilgang til å lese fra og skrive til SQS
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.lambda_queue.arn
      },
      # Gi tilgang til å skrive til den eksisterende S3-bøtten
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${data.aws_s3_bucket.existing_bucket.arn}/*"
      },
      # Gi tilgang til Bedrock for å generere bilder
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
      # Logging for Lambda-funksjonen
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}


# Koble policyen til IAM-rollen
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy16.arn
}


# Definer Lambda-funksjonen
resource "aws_lambda_function" "lambda_sqs_handler16" {
  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]

  filename         = "../lambda_sqs.zip"
  function_name    = "lambda_sqs_handler16"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_sqs.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("../lambda_sqs.zip")

  environment {
    variables = {
      BUCKET_NAME = "pgr301-couch-explorers"
    }
  }
}


# Koble Lambda til SQS-køen
resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = aws_lambda_function.lambda_sqs_handler16.arn
  batch_size       = 10
}



# Referanse til eksisterende S3-bucket
data "aws_s3_bucket" "existing_bucket" {
  bucket = "pgr301-couch-explorers"
}

# Opprett SQS-køen
resource "aws_sqs_queue" "lambda_queue" {
  name = "lambda_sqs_queue_16"
}

# IAM-rolle for Lambda-funksjonen
resource "aws_iam_role" "lambda_execution_role_16" {
  name = "lambda_execution_role_16"

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
  role       = aws_iam_role.lambda_execution_role_16.name
  policy_arn = aws_iam_policy.lambda_policy_16.arn
}


# Definer Lambda-funksjonen
resource "aws_lambda_function" "lambda_sqs_handler16" {
  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]

  filename         = "../lambda_sqs.zip"
  function_name    = "lambda_sqs_handler16"
  role             = aws_iam_role.lambda_execution_role_16.arn
  handler          = "lambda_sqs.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("../lambda_sqs.zip")

  environment {
    variables = {
      BUCKET_NAME = "pgr301-couch-explorers"
      UPLOAD_PATH = "16"
    }
  }
}


# Koble Lambda til SQS-køen
resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = aws_lambda_function.lambda_sqs_handler16.arn
  batch_size       = 10
}


# SNS Topic for varsler
resource "aws_sns_topic" "alarm_topic" {
  name = "sqs-alarm-topic"
}

# SNS Subscription for e-postvarsling
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Alarm for SQS
resource "aws_cloudwatch_metric_alarm" "sqs_approximate_age_alarm" {
  alarm_name          = "SQS-OldestMessageAge-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300 # Alarm utløses hvis meldingen er eldre enn 300 sekunder (5 minutter)
  alarm_description   = "Utløses når den eldste meldingen i SQS-køen er eldre enn 5 minutter"

  # Koble alarmen til SQS-køen
  dimensions = {
    QueueName = aws_sqs_queue.lambda_queue.name
  }

  # Handling når alarm utløses
  alarm_actions = [aws_sns_topic.alarm_topic.arn]
}


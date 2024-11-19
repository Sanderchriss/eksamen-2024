output "lambda_function_arn" {
  value = aws_lambda_function.lambda_sqs_handler16.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.lambda_queue.id
}

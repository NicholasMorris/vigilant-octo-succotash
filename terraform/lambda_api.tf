resource "aws_iam_role" "lambda_exec" {
  name = "social-battery-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_write" {
  name   = "social-battery-dynamodb-write"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem"
      ],
      Effect = "Allow",
      Resource = [aws_dynamodb_table.connections.arn, aws_dynamodb_table.devices.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamo_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_write.arn
}

# Lambda function - you must create a zip file at terraform/lambda/connection_handler.zip containing index.js
resource "aws_lambda_function" "connections" {
  filename         = "${path.module}/lambda/connection_handler.zip"
  function_name    = "social-battery-connections"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.handler"
  runtime          = "python3.11"
  timeout          = 15
  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
      DEVICES_TABLE = aws_dynamodb_table.devices.name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "social-battery-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.connections.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "all_routes" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /connections"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connections.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}


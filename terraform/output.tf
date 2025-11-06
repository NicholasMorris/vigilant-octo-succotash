output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.social_battery_pool.id
  sensitive   = true
}

output "cognito_user_pool_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.social_battery_client.id
  sensitive   = true
}

output "amplify_app_id" {
  description = "Amplify App ID (if hosting a frontend)"
  value       = aws_amplify_app.social_battery_app.id
  sensitive   = true
}

output "aws_region" {
  description = "AWS Region"
  value       = "ap-southeast-2"
  sensitive   = true
}

output "api_endpoint" {
  description = "HTTP API endpoint for the Connections API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}
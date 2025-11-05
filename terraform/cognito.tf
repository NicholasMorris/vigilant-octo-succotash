# --- Cognito User Pool (email only, no verification) ---
resource "aws_cognito_user_pool" "social_battery_pool" {
  name = "social-battery-userpool"

  # Allow sign-in with email only
#   alias_attributes     = ["email"]
  username_attributes  = ["email"]

  # Disable email verification to avoid SES costs and friction
  auto_verified_attributes = []
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  # Basic, free-tier-safe password policy
  password_policy {
    minimum_length    = 6
    require_uppercase = false
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
  }

  # Enable users to sign themselves up
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  mfa_configuration = "OFF"
}

# --- Cognito App Client ---
resource "aws_cognito_user_pool_client" "social_battery_client" {
  name         = "social-battery-client"
  user_pool_id = aws_cognito_user_pool.social_battery_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
  generate_secret = false
}

# --- Optional: Amplify App shell ---
# Only include this if you’re hosting a frontend in Amplify Hosting.
resource "aws_amplify_app" "social_battery_app" {
  name = "social-battery"

  environment_variables = {
    USER_POOL_ID  = aws_cognito_user_pool.social_battery_pool.id
    CLIENT_ID     = aws_cognito_user_pool_client.social_battery_client.id
  }

  tags = {
    Project = "SocialBattery"
    Env     = "dev"
  }
}
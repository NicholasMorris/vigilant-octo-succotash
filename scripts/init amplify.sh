REGION=$(terraform output -raw aws_region)
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)
APP_ID=$(terraform output -raw amplify_app_id)
echo $APP_ID
echo $REGION
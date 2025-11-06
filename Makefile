## Makefile - helpers for Terraform + Lambda deployment
# Usage:
#   make help           - show help
#   make zip-lambda     - create terraform/lambda/connection_handler.zip from app.py
#   make tf-init        - terraform init in terraform/
#   make tf-plan        - terraform plan
#   make tf-apply       - terraform apply (auto-approve)
#   make tf-destroy     - terraform destroy (auto-approve)
#   make deploy         - zip-lambda, init, and apply
#   make outputs        - show terraform outputs (api_endpoint)

TF_DIR=terraform
LAMBDA_SRC=$(TF_DIR)/lambda/connection_handler
LAMBDA_ZIP=$(TF_DIR)/lambda/connection_handler.zip

.PHONY: help zip-lambda tf-init tf-plan tf-apply tf-destroy deploy outputs clean

help:
	@echo "Makefile targets:"
	@echo "  zip-lambda   - package the Python lambda into $(LAMBDA_ZIP)"
	@echo "  tf-init      - terraform init in $(TF_DIR)"
	@echo "  tf-plan      - terraform plan in $(TF_DIR)"
	@echo "  tf-apply     - terraform apply (auto-approve) in $(TF_DIR)"
	@echo "  tf-destroy   - terraform destroy (auto-approve) in $(TF_DIR)"
	@echo "  deploy       - zip-lambda, tf-init, tf-apply"
	@echo "  outputs      - show terraform outputs (api_endpoint)"

# Create lambda zip at terraform/lambda/connection_handler.zip
zip-lambda:
	@echo "Creating lambda zip -> $(LAMBDA_ZIP)"
	@test -d $(LAMBDA_SRC) || (echo "Lambda source not found: $(LAMBDA_SRC)" && exit 1)
	@cd $(LAMBDA_SRC) && rm -f ../connection_handler.zip && zip -r ../connection_handler.zip app.py >/dev/null
	@echo "Wrote $(LAMBDA_ZIP)"

tf-init:
	@echo "Initializing terraform in $(TF_DIR)"
	@terraform -chdir=$(TF_DIR) init

tf-plan:
	@echo "Terraform plan in $(TF_DIR)"
	@terraform -chdir=$(TF_DIR) plan

tf-apply: zip-lambda tf-init
	@echo "Applying terraform in $(TF_DIR)"
	@terraform -chdir=$(TF_DIR) apply -auto-approve

tf-destroy:
	@echo "Destroying terraform-managed resources in $(TF_DIR)"
	@terraform -chdir=$(TF_DIR) destroy -auto-approve

deploy: tf-apply
	@echo "Deployment complete. Run 'make outputs' to see the API endpoint."

outputs:
	@terraform -chdir=$(TF_DIR) output

clean:
	@echo "Cleaning generated lambda zip"
	@rm -f $(LAMBDA_ZIP)

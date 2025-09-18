update-form-html:
	bash update_form_html.sh

apply-prod:
	terraform apply -var-file=environments/prod/prod.tfvars -auto-approve || (echo "Terraform apply failed. Checking for specific issues..." && \
	terraform show && \
	echo "Attempting to resolve common issues..." && \
	terraform init -var-file=environments/prod/prod.tfvars && \
	terraform apply -var-file=environments/prod/prod.tfvars -auto-approve)

apply:
	make apply-prod

upload-s3-prod:
	BUCKET_NAME=$$(terraform output -raw ui_bucket_name) && aws s3 cp form.html s3://$$BUCKET_NAME/form.html

upload-s3:
	make upload-s3-prod

all:
	make apply-prod
	make update-form-html
	make upload-s3-prod

# Gerenciar arquivos de estado local do Terraform
.PHONY: limpar-estado iniciar-estado capturar-estado planejar-estado

limpar-estado:
	rm -rf environments/dev/.terraform
	rm -rf environments/prod/.terraform
	rm -f environments/dev/tfplan
	rm -f environments/prod/tfplan

iniciar-estado:
	cd environments/prod && terraform init -var-file=prod.tfvars

capturar-estado:
	cd environments/prod && terraform show -json > tfplan

planejar-estado:
	cd environments/prod && terraform plan -var-file=prod.tfvars -out=tfplan

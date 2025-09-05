update-form-html:
	bash update_form_html.sh

apply:
	terraform apply -auto-approve
	make update-form-html

upload-s3:
	BUCKET_NAME=$$(terraform output -raw ui_bucket_name) && aws s3 cp form.html s3://$$BUCKET_NAME/form.html

all:
	make apply
	make upload-s3

# Gerenciar arquivos de estado local do Terraform
.PHONY: limpar-estado iniciar-estado capturar-estado planejar-estado

limpar-estado:
	rm -rf environments/dev/.terraform
	rm -rf environments/prod/.terraform
	rm -f environments/dev/tfplan
	rm -f environments/prod/tfplan

iniciar-estado:
	cd environments/dev && terraform init
	cd environments/prod && terraform init

capturar-estado:
	cd environments/dev && terraform show -json > tfplan
	cd environments/prod && terraform show -json > tfplan

planejar-estado:
	cd environments/dev && terraform plan -out=tfplan
	cd environments/prod && terraform plan -out=tfplan

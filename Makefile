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

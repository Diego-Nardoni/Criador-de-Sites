# Empacotamento dos códigos Lambda
resource "null_resource" "lambda_zips" {
  triggers = {
    validate_input = filemd5("${path.module}/lambdas/validate_input.py")
    generate_html  = filemd5("${path.module}/lambdas/generate_html.py")
    store_site     = filemd5("${path.module}/lambdas/store_site.py")
    update_status  = filemd5("${path.module}/lambdas/update_status.py")
    notify_user    = filemd5("${path.module}/lambdas/notify_user.py")
    enqueue        = filemd5("${path.module}/lambdas/enqueue.py")
    sqs_invoker    = filemd5("${path.module}/lambdas/sqs_invoker.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/lambdas
      zip ../lambda_validate_input.zip validate_input.py
      zip ../lambda_generate_html.zip generate_html.py
      zip ../lambda_store_site.zip store_site.py
      zip ../lambda_update_status.zip update_status.py
      zip ../lambda_notify_user.zip notify_user.py
      zip ../lambda_enqueue.zip enqueue.py
      zip ../lambda_sqs_invoker.zip sqs_invoker.py
    EOT
  }
}

data "archive_file" "lambda_validate_input_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/validate_input.py"
  output_path = "${path.module}/lambda_validate_input.zip"
}

data "archive_file" "lambda_generate_html_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/generate_html.py"
  output_path = "${path.module}/lambda_generate_html.zip"
}

data "archive_file" "lambda_store_site_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/store_site.py"
  output_path = "${path.module}/lambda_store_site.zip"
}

data "archive_file" "lambda_update_status_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/update_status.py"
  output_path = "${path.module}/lambda_update_status.zip"
}

data "archive_file" "lambda_notify_user_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/notify_user.py"
  output_path = "${path.module}/lambda_notify_user.zip"
}

data "archive_file" "lambda_enqueue_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/enqueue.py"
  output_path = "${path.module}/lambda_enqueue.zip"
}

data "archive_file" "lambda_sqs_invoker_zip" {
  depends_on = [null_resource.lambda_zips]
  type        = "zip"
  source_file = "${path.module}/lambdas/sqs_invoker.py"
  output_path = "${path.module}/lambda_sqs_invoker.zip"
}

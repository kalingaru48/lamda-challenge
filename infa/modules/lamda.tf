# Archive node-module for Lambda layer
data "archive_file" "lambda_layer_module_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lamda-layer-code"
  output_path = "${path.module}/lamda-layer-code/lambda-layer.zip"
}
# Create S3 bucket to store Lambda layer code
resource "aws_s3_bucket" "lambda_layer_bucket" {
  bucket = "temp-lambda-layer-bucket"
  force_destroy = true
  
  lifecycle {
    prevent_destroy = false
  }
}
# Upload Lambda layer zip file to S3 bucket
resource "aws_s3_object" "lambda_layer_zip" {
  bucket = aws_s3_bucket.lambda_layer_bucket.bucket
  key    = "lambda-layer.zip"
  source = data.archive_file.lambda_layer_module_zip.output_path
  source_hash  = filemd5(data.archive_file.lambda_layer_module_zip.output_path)
  acl    = "private"
}
# Create Lambda layer from the S3 bucket zip file
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "task-api-lambda-layer"
  s3_bucket           = aws_s3_bucket.lambda_layer_bucket.bucket
  s3_key              = aws_s3_object.lambda_layer_zip.key
  compatible_runtimes = ["nodejs 22.x"]
  source_code_hash    = filemd5(data.archive_file.lambda_layer_module_zip.output_path)
  # Ensure the layer creation depends on the bucket and object
  depends_on = [aws_s3_object.lambda_layer_zip]
}

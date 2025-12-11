#create permission for trigger
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.raw_csv_update_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::term-project3280"
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = "term-project3280"
  lambda_function {
    lambda_function_arn = aws_lambda_function.raw_csv_update_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "user_data/"
    filter_suffix       = ".csv"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

#create layer
#upload to s3 first
resource "aws_s3_object" "lambda_layer_zip" {
  bucket = "term-project3280"
  key    = "lambda_layer/lambda-layer.zip"
  source = "lambda-layer.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}


resource "aws_lambda_layer_version" "python_layer" {
  layer_name          = "python_layer"
  compatible_runtimes = ["python3.11"]
  description         = "Custom Lambda layer with boto3, numpy and pandas"
  s3_bucket           = "term-project3280"
  s3_key              = aws_s3_object.lambda_layer_zip.key
}

#upload lambda function zip files to s3
resource "aws_s3_object" "createCrawlerForEmbedding_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/createCrawlerForEmbedding.zip"
  source = "lambda_functions/createCrawlerForEmbedding.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "createCrawlerForMusicData_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/createCrawlerForMusicData.zip"
  source = "lambda_functions/createCrawlerForMusicData.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "createCrawlerForProcessedMusicData_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/createCrawlerForProcessedMusicData.zip"
  source = "lambda_functions/createCrawlerForProcessedMusicData.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "raw_csv_update_trigger_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/raw_csv_update_trigger.zip"
  source = "lambda_functions/raw_csv_update_trigger.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "raw_parquet_distributer_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/raw_parquet_distributer.zip"
  source = "lambda_functions/raw_parquet_distributer.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "start_embedding_job_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/start_embedding_job.zip"
  source = "lambda_functions/start_embedding_job.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "start_aggregate_glue_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/start_aggregate_glue.zip"
  source = "lambda_functions/start_aggregate_glue.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

resource "aws_s3_object" "ApiQueryHandler_zip" {
  bucket = "term-project3280"
  key    = "lambda_functions/ApiQueryHandler.zip"
  source = "lambda_functions/ApiQueryHandler.zip"
  depends_on = [aws_s3_bucket.project_bucket]
}

#create lambda functions from s3 zip files
resource "aws_lambda_function" "createCrawlerForEmbedding" {
  function_name = "createCrawlerForEmbedding"
  role          = aws_iam_role.crawlRawDataLambdaCustome.arn
  handler       = "createCrawlerForEmbedding.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.createCrawlerForEmbedding_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "createCrawlerForMusicData" {
  function_name = "createCrawlerForMusicData"
  role          = aws_iam_role.crawlRawDataLambdaCustome.arn
  handler       = "createCrawlerForMusicData.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.createCrawlerForMusicData_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "createCrawlerForProcessedMusicData" {
  function_name = "createCrawlerForProcessedMusicData"
  role          = aws_iam_role.crawlRawDataLambdaCustome.arn
  handler       = "createCrawlerForProcessedMusicData.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.createCrawlerForProcessedMusicData_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "raw_csv_update_trigger" {
  function_name = "raw_csv_update_trigger"
  role          = aws_iam_role.LambdaStartGlueRole.arn
  handler       = "raw_csv_update_trigger.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.raw_csv_update_trigger_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "raw_parquet_distributer" {
  function_name = "raw_parquet_distributer"
  role          = aws_iam_role.LambdaStartGlueRole.arn
  handler       = "raw_parquet_distributer.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.raw_parquet_distributer_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "start_embedding_job" {
  function_name = "start_embedding_job"
  role          = aws_iam_role.LambdaStartGlueRole.arn
  handler       = "start_embedding_job.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.start_embedding_job_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "start_aggregate_glue" {
  function_name = "start_aggregate_glue"
  role          = aws_iam_role.LambdaStartGlueRole.arn
  handler       = "start_aggregate_glue.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.start_aggregate_glue_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}

resource "aws_lambda_function" "ApiQueryHandler" {
  function_name = "ApiQueryHandler"
  role          = aws_iam_role.LambdaQueryApiRole.arn
  handler       = "ApiQueryHandler.lambda_handler"
  runtime       = "python3.11"
  s3_bucket     = "term-project3280"
  s3_key        = aws_s3_object.ApiQueryHandler_zip.key
  layers        = [aws_lambda_layer_version.python_layer.arn]
  timeout       = 120 
}
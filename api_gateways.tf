resource "aws_apigatewayv2_api" "termproject_api" {
  name          = "termproject_api"
  protocol_type = "HTTP"
}

#api for start_aggregate_job

resource "aws_apigatewayv2_integration" "start_embedding_job_integration" {
  api_id           = aws_apigatewayv2_api.termproject_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.start_embedding_job.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_start_embedding" {
  api_id    = aws_apigatewayv2_api.termproject_api.id
  route_key = "GET /start_embedding_job"
  target    = "integrations/${aws_apigatewayv2_integration.start_embedding_job_integration.id}"
}

resource "aws_lambda_permission" "allow_get_permission" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_embedding_job.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.termproject_api.execution_arn}/*/GET/start_embedding_job"
}


#api for ApiQueryHandler

resource "aws_apigatewayv2_integration" "ApiQueryHandler_integration" {
  api_id                  = aws_apigatewayv2_api.termproject_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.ApiQueryHandler.arn
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "post_ApiQueryHandler" {
  api_id    = aws_apigatewayv2_api.termproject_api.id
  route_key = "POST /ApiQueryHandler"
  target    = "integrations/${aws_apigatewayv2_integration.ApiQueryHandler_integration.id}"
}

resource "aws_lambda_permission" "allow_post_permission" {
  statement_id  = "AllowExecutionFromAPIGatewayPost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ApiQueryHandler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.termproject_api.execution_arn}/*/POST/ApiQueryHandler"
}


resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.termproject_api.id
  name        = "prod"
  auto_deploy = true
}
# Data source to fetch the latest published JAR URL from S3
data "aws_s3_bucket_object" "latest_jar" {
  bucket = "mycoderepo"  # Update with your S3 bucket name
  key    = "SpringBootDev/BuildTest-0.0.1-SNAPSHOT.jar"  # Update with your JAR path
}


resource "aws_lambda_function" "my_lambda_function" {
  function_name    = "your_lambda_function_name"
  handler          = "com.example.BuildTest.LambdaHandler::handleRequest"
  runtime          = "java17"  # Update with your desired runtime
  role             = aws_iam_role.lambda.arn
  timeout          = 60
  memory_size      = 512
  publish          = true
  source_code_hash = data.aws_s3_bucket_object.latest_jar.etag

  s3_bucket = "mycoderepo"
  s3_key    = "SpringBootDev/BuildTest-0.0.1-SNAPSHOT.jar" 
  environment {
    variables = {
      KEY1 = "VALUE1",
      KEY2 = "VALUE2",
      # Add any environment variables your Lambda function requires
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = "lambda-execution-role"  # Update with your desired role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

# Attach AWSLambdaBasicExecutionRole policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}


#API GATEWAY CREATION
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "BuildTestApis"
  description = "BuildTestApi Gateway API Gateway"
}

resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on   = [aws_api_gateway_integration.example_integration]
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  stage_name    = "dev"
}
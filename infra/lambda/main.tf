data "terraform_remote_state" "dynamodb" {
  backend = "s3"

  config = {
    bucket = "resume-cloud-native-tfstate"
    key    = "dynamodb/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/../../backend/visitor_counter/handler.py"
  output_path = "${path.module}/build/handler.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.function_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [data.terraform_remote_state.dynamodb.outputs.table_arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "${var.function_name}-dynamodb-access"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = data.terraform_remote_state.dynamodb.outputs.table_name
    }
  }
}

resource "aws_iam_role" "lambdaRole" {
  name = "lambdaRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Action" : [
          "sts:AssumeRole"
        ]
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambdaS3Policy" {
  name = "lambdaS3Policy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        Effect : "Allow"
        Action : [
          "s3:GetObject"
        ]
        Resource : "${aws_s3_bucket.mySourceBucket.arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : "arn:aws:dynamodb:us-east-1:851725188350:table/Movies"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambdaS3Policy.arn
  roles      = [aws_iam_role.lambdaRole.name]
  name       = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambdaFile" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "importCSV" {
  role             = aws_iam_role.lambdaRole.arn
  filename         = data.archive_file.lambdaFile.output_path
  source_code_hash = data.archive_file.lambdaFile.output_base64sha256
  function_name    = "importCSV"
  timeout          = 60
  runtime          = "python3.9"
  handler          = "lambda.lambda_handler"
}

resource "aws_lambda_permission" "importCSVPermission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.importCSV.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.mySourceBucket.arn
}

resource "aws_s3_bucket_notification" "bucketNotification" {
  bucket = aws_s3_bucket.mySourceBucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.importCSV.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.importCSVPermission]
}
data "archive_file" "create_winrm_package" {
  type        = "zip"
  source_dir  = "${path.module}/include/winrm-package"
  output_path = ".terraform/winrm-package.zip"
}

resource "aws_iam_role" "lambda_winrm" {
  name = "${var.customer}-lambda-winrm-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]

}
EOF
}

resource "aws_lambda_function" "lambda_winrm" {
  filename         = ".terraform/winrm-package.zip"
  source_code_hash = "${data.archive_file.create_winrm_package.output_base64sha256}"
  function_name    = "lambda_winrm"
  role             = "${aws_iam_role.lambda_winrm.arn}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python2.7"
  timeout          = "30"

  vpc_config {
    subnet_ids         = ["${var.lambda_subnets}"]
    security_group_ids = ["${var.lambda_sgs}", "${aws_security_group.winrm.id}"]
  }

  environment {
    variables = {
      env_username = "${var.username}"
      env_password = "${var.password}"
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_winrm.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.lambda-winrm.arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.lambda-winrm.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda_winrm.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_iam_policy" "cloudwatch_logaccess" {
  name        = "${var.customer}-cloudwatch-logs"
  path        = "/"
  description = "cloudwatch_logs"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "s3:*",
        "ec2:Describe*",
        "ec2:CreateNetworkInterface",
        "ec2:CreateSnapshot",
        "ec2:ModifySnapshotAttribute",
        "ec2:ResetSnapshotAttribute",
        "ec2:AttachNetworkInterface",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "attachlogaccess" {
  name       = "${var.customer}-allow-access-to-logs"
  roles      = ["${aws_iam_role.lambda_winrm.name}"]
  policy_arn = "${aws_iam_policy.cloudwatch_logaccess.arn}"
}

resource "aws_security_group" "winrm" {
  name        = "winrm"
  vpc_id      = "${var.vpc_id}"
  description = "winrm security group"
}

resource "aws_security_group_rule" "winrm_out" {
  type              = "egress"
  protocol          = "tcp"
  from_port         = "5985"
  to_port           = "5986"
  security_group_id = "${aws_security_group.winrm.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_s3_bucket" "lambda-winrm" {
  bucket        = "${var.customer}-${var.envtype}-lambda-winrm"
  force_destroy = true

  tags {
    Name        = "${var.customer}"
    Environment = "${var.envname}"
    Envtype     = "${var.envtype}"
  }
}

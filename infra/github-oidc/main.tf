data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only workflow runs triggered on main can assume this role — matches
    # the backend pipeline only ever running on merge to main.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_actions_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "backend_deploy" {
  statement {
    sid     = "TerraformStateAccess"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::resume-cloud-native-tfstate",
      "arn:aws:s3:::resume-cloud-native-tfstate/*",
    ]
  }

  statement {
    sid = "DynamoDBTableManagement"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:ListTagsOfResource",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeContinuousBackups",
    ]
    resources = ["arn:aws:dynamodb:${var.region}:${var.account_id}:table/resume-visitor-count"]
  }

  statement {
    sid = "LambdaFunctionManagement"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:ListVersionsByFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags",
      "lambda:GetPolicy",
      "lambda:AddPermission",
      "lambda:RemovePermission",
    ]
    resources = ["arn:aws:lambda:${var.region}:${var.account_id}:function:resume-visitor-counter"]
  }

  statement {
    sid = "LambdaExecRoleManagement"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::${var.account_id}:role/resume-visitor-counter-exec"]
  }

  statement {
    sid       = "ApiGatewayManagement"
    actions   = ["apigateway:GET", "apigateway:POST", "apigateway:PUT", "apigateway:PATCH", "apigateway:DELETE"]
    resources = ["arn:aws:apigateway:${var.region}::/apis", "arn:aws:apigateway:${var.region}::/apis/*"]
  }
}

resource "aws_iam_role_policy" "backend_deploy" {
  name   = "${var.role_name}-backend-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.backend_deploy.json
}

data "aws_iam_policy_document" "frontend_deploy" {
  statement {
    sid     = "SiteBucketSync"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.site_bucket_name}",
      "arn:aws:s3:::${var.site_bucket_name}/*",
    ]
  }

  statement {
    sid       = "CloudFrontInvalidation"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${var.account_id}:distribution/${var.cloudfront_distribution_id}"]
  }
}

resource "aws_iam_role_policy" "frontend_deploy" {
  name   = "${var.role_name}-frontend-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.frontend_deploy.json
}

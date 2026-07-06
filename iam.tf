# ------------------------------
# Account
# ------------------------------
data "aws_caller_identity" "current" {}

# ------------------------------
# GitHub Actions OIDC Provider
# ------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = {
    Name    = "${var.project}-github-actions-oidc"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# IAM Role (assumed by GitHub Actions)
# ------------------------------
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:kiskm/tabi-note-deploy:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project}-${var.environment}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Name    = "${var.project}-${var.environment}-github-actions-deploy"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# IAM Policy (permissions used by deploy.yml)
# ------------------------------
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.project}-${var.environment}-github-actions-deploy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

# ------------------------------
# IAM Role (assumed by GitHub Actions, for terraform plan)
# ------------------------------
data "aws_iam_policy_document" "github_actions_plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:kiskm/tabi-note-deploy:ref:refs/heads/main",
        "repo:kiskm/tabi-note-deploy:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_plan" {
  name               = "${var.project}-${var.environment}-github-actions-plan"
  assume_role_policy = data.aws_iam_policy_document.github_actions_plan_trust.json

  tags = {
    Name    = "${var.project}-${var.environment}-github-actions-plan"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# IAM Policy (permissions used by plan.yml)
# ------------------------------
data "aws_iam_policy_document" "github_actions_plan_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "iam:Get*",
      "iam:List*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::tabi-note-tfstate"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["arn:aws:s3:::tabi-note-tfstate/tabi-note/terraform.tfstate"]
  }
}

resource "aws_iam_role_policy" "github_actions_plan" {
  name   = "${var.project}-${var.environment}-github-actions-plan"
  role   = aws_iam_role.github_actions_plan.id
  policy = data.aws_iam_policy_document.github_actions_plan_permissions.json
}

# ------------------------------
# IAM Role (assumed by GitHub Actions, for terraform apply)
# ------------------------------
data "aws_iam_policy_document" "github_actions_apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:kiskm/tabi-note-deploy:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_apply" {
  name               = "${var.project}-${var.environment}-github-actions-apply"
  assume_role_policy = data.aws_iam_policy_document.github_actions_apply_trust.json

  tags = {
    Name    = "${var.project}-${var.environment}-github-actions-apply"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# IAM Policy (permissions used by apply.yml)
# ------------------------------
data "aws_iam_policy_document" "github_actions_apply_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::tabi-note-tfstate"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::tabi-note-tfstate/tabi-note/terraform.tfstate"]
  }
}

resource "aws_iam_role_policy" "github_actions_apply" {
  name   = "${var.project}-${var.environment}-github-actions-apply"
  role   = aws_iam_role.github_actions_apply.id
  policy = data.aws_iam_policy_document.github_actions_apply_permissions.json
}

# ------------------------------
# Output
# ------------------------------
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_plan_role_arn" {
  value = aws_iam_role.github_actions_plan.arn
}

output "github_actions_apply_role_arn" {
  value = aws_iam_role.github_actions_apply.arn
}

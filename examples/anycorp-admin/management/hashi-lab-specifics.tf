data "aws_iam_policy" "demo_user_permissions_boundary" {
  name = "DemoUser"
}

resource "aws_iam_user_policy_attachment" "permissions_boundary" {
  user       = aws_iam_user.secrets_engine.name
  policy_arn = data.aws_iam_policy.demo_user_permissions_boundary.arn
}

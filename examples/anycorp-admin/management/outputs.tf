output "iam_user_name" {
  value       = aws_iam_user.secrets_engine.name
  description = "The name of the IAM user created for the AWS Secrets Engine."
}

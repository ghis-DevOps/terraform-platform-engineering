data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "trail_bucket" {
  bucket        = "webforx-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.trail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.trail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "global_trail" {
  name                          = "webforx-global-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  depends_on = [aws_s3_bucket_policy.trail_bucket_policy]
}

resource "aws_dynamodb_table" "config_snapshots" {
  name         = "webforx-config-snapshots"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SnapshotId"

  attribute {
    name = "SnapshotId"
    type = "S"
  }
}

resource "aws_config_configuration_recorder" "main" {
  name     = "webforx-config-recorder"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported = true
  }
}

resource "aws_iam_role" "config_role" {
  name = "webforx-aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "sandbox_permission_boundary" {
  name        = "webforx-sandbox-boundary"
  description = "Enforces strict security rules and naming guidelines"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyNonUsEast1"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = { "aws:RequestedRegion" : ["us-east-1"] }
        }
      },
      {
        Sid      = "DenyBareMetalInstances"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringLike = { "ec2:InstanceType" : ["*.metal*"] }
        }
      },
      {
        Sid      = "BlockIAMUserLifecycle"
        Effect   = "Deny"
        Action   = ["iam:CreateUser", "iam:DeleteUser"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "ebs_key" {
  description             = "KMS Key for EBS Volume Encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS Key for S3 Bucket Encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}
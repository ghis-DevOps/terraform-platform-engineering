# Public ACM Certificate setup
resource "aws_acm_certificate" "public_cert" {
  domain_name       = "sandbox.webforx.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic File System (EFS) Setup
resource "aws_efs_file_system" "shared_efs" {
  creation_token   = "webforx-shared-efs"
  performance_mode = "generalPurpose"
  encrypted        = true

  tags = { Name = "webforx-shared-efs" }
}

resource "aws_efs_mount_target" "mount_targets" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.shared_efs.id
  subnet_id       = var.private_subnet_ids[count.index]
}

# AWS Backup Plan configuration
resource "aws_backup_vault" "main_vault" {
  name        = "webforx-backup-vault"
}

resource "aws_backup_plan" "ec2_backup_plan" {
  name = "webforx-ec2-daily-backup-plan"

  rule {
    rule_name         = "daily_backup_rule"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 12 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }
}
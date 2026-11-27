data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "wikijs" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.wikijs.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "rds_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "rds_secret" {
  name   = "${var.project_name}-rds-secret-read"
  role   = aws_iam_role.wikijs.id
  policy = data.aws_iam_policy_document.rds_secret.json
}

resource "aws_iam_instance_profile" "wikijs" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.wikijs.name
}

locals {
  cloudwatch_config = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }
    metrics = {
      namespace              = "WikiJS/Infrastructure"
      aggregation_dimensions = [["InstanceId"]]
      append_dimensions      = { InstanceId = "$${aws:InstanceId}" }
      metrics_collected = {
        mem = {
          measurement                 = ["mem_used_percent"]
          metrics_collection_interval = 60
        }
        disk = {
          measurement                 = ["used_percent"]
          metrics_collection_interval = 60
          resources                   = ["/"]
          drop_original_metrics       = ["used_percent"]
        }
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/cloud-init-output.log"
              log_group_name  = var.log_group_name
              log_stream_name = "{instance_id}/cloud-init"
            },
            {
              file_path       = "/var/lib/docker/containers/*/*-json.log"
              log_group_name  = var.log_group_name
              log_stream_name = "{instance_id}/docker"
            }
          ]
        }
      }
    }
  })
}

resource "aws_instance" "wikijs" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.wikijs.name
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../../user_data.sh.tftpl", {
    db_name                = var.db_name
    db_username            = var.db_username
    db_host                = var.db_host
    db_port                = var.db_port
    db_secret_arn          = var.db_secret_arn
    aws_region             = var.aws_region
    cloudwatch_config_json = local.cloudwatch_config
  })
  user_data_replace_on_change = true

  # IAM profile must have permission before cloud-init retrieves RDS credentials.
  depends_on = [
    aws_iam_role_policy.rds_secret,
    aws_iam_role_policy_attachment.cloudwatch
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {

    Name = "${var.project_name}-ec2"

  }
}

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

resource "aws_instance" "wikijs" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../../user_data.sh.tftpl", {
    compose_b64 = base64encode(templatefile("${path.module}/../../docker-compose.yml.tftpl", {
      db_host          = var.db_host
      db_port          = var.db_port
      db_name          = var.db_name
      db_username      = var.db_username
      db_password      = var.db_password
      grafana_password = var.grafana_password
    }))
    prometheus_b64 = filebase64("${path.module}/../../monitoring/prometheus.yml")
    datasource_b64 = filebase64("${path.module}/../../monitoring/grafana/datasource.yml")
    dashboards_b64 = filebase64("${path.module}/../../monitoring/grafana/dashboards.yml")
    dashboard_b64  = filebase64("${path.module}/../../monitoring/grafana/dashboard.json")
  })
  user_data_replace_on_change = true

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

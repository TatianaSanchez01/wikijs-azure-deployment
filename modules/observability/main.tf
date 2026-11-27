resource "aws_cloudwatch_dashboard" "wikijs" {
  dashboard_name = "${var.project_name}-observability"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "EC2: CPU y memoria (%)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id],
            ["WikiJS/Infrastructure", "mem_used_percent", "InstanceId", var.ec2_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "RDS: CPU y conexiones"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "EC2: espacio usado en disco (%)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["WikiJS/Infrastructure", "disk_used_percent", "InstanceId", var.ec2_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "RDS: espacio libre (bytes)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier]
          ]
        }
      }
    ]
  })
}

resource "aws_sns_topic" "alarms" {
  count = var.alert_email == "" ? 0 : 1
  name  = "${var.project_name}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  alarm_actions = var.alert_email == "" ? [] : [aws_sns_topic.alarms[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-ec2-high-cpu"
  alarm_description   = "EC2 con CPU promedio superior a 80% durante 10 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = { InstanceId = var.ec2_instance_id }
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${var.project_name}-ec2-status-check-failed"
  alarm_description   = "Fallo de comprobación de estado EC2"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = { InstanceId = var.ec2_instance_id }
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory" {
  alarm_name          = "${var.project_name}-ec2-high-memory"
  alarm_description   = "Memoria usada superior a 85% durante 10 minutos"
  namespace           = "WikiJS/Infrastructure"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = { InstanceId = var.ec2_instance_id }
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  alarm_description   = "RDS con menos de 2 GiB libres"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.alarm_actions
}

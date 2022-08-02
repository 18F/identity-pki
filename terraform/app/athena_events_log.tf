locals{
  events_log_bucket_name   = "login-gov-log-cache-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_iam_policy_document" "cloudwatch_process_logs" {
  statement {
    sid    = "AllowProcessCloudWatchLogs"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.events_log_bucket_name}",
      "arn:aws:s3:::${local.events_log_bucket_name}/*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_process_logs" {
  name   = "${var.env_name}-cloudwatch-process-logs"
  role   = module.cloudwatch_events_log_processors.cloudwatch_log_processor_lambda_iam_role.id
  policy = data.aws_iam_policy_document.cloudwatch_process_logs.json
}

module "cloudwatch_events_log_processors"{
  source        = "../modules/cloudwatch_log_processors"
  kms_resources =  [module.kinesis-firehose.kinesis_firehose_stream_bucket]

  env_name      = var.env_name
  region        = var.region
  bucket_name   = local.events_log_bucket_name
}

module "athena_logs_database"{
  source        = "../modules/athena_database"
  database_name = "${var.env_name}_events_logs"
  bucket_name   = local.events_log_bucket_name
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "${var.env_name}_events_log"
  database_name = "${module.athena_logs_database.database.name}"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                    = "TRUE"
    "parquet.compression"       = "SNAPPY"
    "has_encrypted_data"        = "true", 
    "projection.day.digits"     = "2", 
    "projection.day.range"      = "01,31", 
    "projection.day.type"       = "integer", 
    "projection.enabled"        = "true", 
    "projection.hour.digits"    = "2", 
    "projection.hour.range"     = "00,23", 
    "projection.hour.type"      = "integer", 
    "projection.month.digits"   = "2", 
    "projection.month.range"    = "01,12", 
    "projection.month.type"     = "integer", 
    "projection.year.digits"    = "4", 
    "projection.year.range"     = "2021,2022", 
    "projection.year.type"      = "integer", 
    "storage.location.template" = "s3://${local.events_log_bucket_name}/athena/$${year}/$${month}/$${day}/$${hour}", 
    "transient_lastDdlTime"     = "1657034075"
  }

  partition_keys {
    name    = "year"
    type    = "int"
  }

  partition_keys {
    name    = "month"
    type    = "int"
  }

  partition_keys {
    name    = "day"
    type    = "int"
  }

  partition_keys {
    name    = "hour"
    type    = "int"
  }

  
  storage_descriptor {
    location      = "s3://${local.events_log_bucket_name}/athena"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "kinesis-stream"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "name"
      type = "string"
    }

    columns {
      name = "my_struct"
      type = "struct<event_properties:struct<requested_ial:string,service_provider:string,flash:string,stored_location:string>,new_event:boolean,new_session_path:boolean,new_session_success_state:boolean,success_state:string,path:string,session_duration:float,user_id:string,locale:string,user_ip:string,hostname:string,pid:int,service_provider:string,trace_id:string,git_sha:string,git_branch:string,user_agent:string,browser_name:string,browser_version:string,browser_platform_name:string,browser_platform_version:string,browser_device_name:string,browser_mobile:boolean,browser_bot:boolean>"
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "visitor_id"
      type = "string"
    }

    columns {
      name = "visit_id"
      type = "string"
    }

    columns {
      name = "duration_ms"
      type = "string"
    }

    columns {
      name = "job_class"
      type = "string"
    }

    columns {
      name = "trace_id"
      type = "string"
    }

    columns {
      name = "queue_name"
      type = "string"
    }

    columns {
      name = "job_id"
      type = "string"
    }

    columns {
      name = "original"
      type = "string"
    }
  }

}

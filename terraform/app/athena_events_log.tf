module "athena_events_log_database" {
  source        = "../modules/athena_database"
  database_name = "${var.env_name}_logs"
  kms_key       = module.kinesis-firehose.kinesis_firehose_stream_bucket_kms_key.arn
  kms_resources = [module.kinesis-firehose.kinesis_firehose_stream_bucket_kms_key.arn]
  process_logs  = false
  env_name      = var.env_name
  region        = var.region
  bucket_name   = module.kinesis-firehose.kinesis_firehose_stream_bucket.bucket
  source_arn    = module.kinesis-firehose.kinesis_firehose_stream_bucket.arn

  depends_on = [module.kinesis-firehose]
}

resource "aws_glue_catalog_table" "athena_events_log_database" {
  name          = "${var.env_name}_events_log"
  database_name = module.athena_events_log_database.database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                  = "TRUE"
    "parquet.compression"     = "SNAPPY"
    "has_encrypted_data"      = "true",
    "projection.day.digits"   = "2",
    "projection.day.range"    = "01,31",
    "projection.day.type"     = "integer",
    "projection.enabled"      = "true",
    "projection.hour.digits"  = "2",
    "projection.hour.range"   = "00,23",
    "projection.hour.type"    = "integer",
    "projection.month.digits" = "2",
    "projection.month.range"  = "01,12",
    "projection.month.type"   = "integer",
    "projection.year.digits"  = "4",
    "projection.year.range"   = "2021,2022",
    "projection.year.type"    = "integer",
    "storage.location.template" = join("/", [
      "s3:/",
      module.kinesis-firehose.kinesis_firehose_stream_bucket.bucket,
      "athena/$${year}/$${month}/$${day}/$${hour}",
    ])
    "transient_lastDdlTime" = "1657034075"
  }

  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  partition_keys {
    name = "day"
    type = "int"
  }

  partition_keys {
    name = "hour"
    type = "int"
  }


  storage_descriptor {
    location      = "s3://${module.kinesis-firehose.kinesis_firehose_stream_bucket.bucket}/athena"
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
      name = "properties"
      type = join("", [
        "struct<",
        "event_properties:struct<",
        "requested_ial:string,service_provider:string,",
        "flash:string,stored_location:string",
        ">,",
        "new_event:boolean,new_session_path:boolean,new_session_success_state:boolean,",
        "success_state:string,path:string,session_duration:float,user_id:string,",
        "locale:string,user_ip:string,hostname:string,pid:int,service_provider:string,",
        "trace_id:string,git_sha:string,git_branch:string,user_agent:string,",
        "browser_name:string,browser_version:string,browser_platform_name:string,",
        "browser_platform_version:string,browser_device_name:string,",
        "browser_mobile:boolean,browser_bot:boolean",
        ">"
      ])
    }

    columns {
      name = "time"
      type = "string"
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

  depends_on = [
    module.athena_events_log_database,
    module.kinesis-firehose.kinesis_firehose_stream_bucket
  ]

}

resource "aws_athena_named_query" "success_state" {
  name      = "Totals by success_state over the last 7 days"
  workgroup = aws_athena_workgroup.environment_workgroup.id
  database  = module.athena_events_log_database.database.name
  query     = <<EOT
              SELECT properties.success_state, COUNT(properties.success_state) AS total
              FROM "${var.env_name}_logs"."${var.env_name}_events_log"
              WHERE from_iso8601_timestamp(time) > from_iso8601_timestamp(time) - interval '7' day
              GROUP BY properties.success_state
              ORDER BY total desc
              EOT
}

resource "aws_athena_named_query" "user_ips" {
  name      = "Top 10 User IPs for a given day"
  workgroup = aws_athena_workgroup.environment_workgroup.id
  database  = module.athena_events_log_database.database.name
  query     = <<EOT
              SELECT properties.user_ip , count(properties.user_ip) AS total
              FROM "${var.env_name}_logs"."${var.env_name}_events_log"
              WHERE year = ? AND month = ? AND DAY = ? AND properties.browser_bot = false
              GROUP BY properties.user_ip
              ORDER BY total desc
              LIMIT 10
              EOT
}

resource "aws_athena_named_query" "browser_platforms" {
  name      = "Top 10 Browser/Platform combinations for a given day"
  workgroup = aws_athena_workgroup.environment_workgroup.id
  database  = module.athena_events_log_database.database.name
  query     = <<EOT
              SELECT properties.browser_name, properties.browser_version,
                properties.browser_platform_name, properties.browser_platform_version,
                COUNT(*) as total
              FROM "${var.env_name}_logs"."${var.env_name}_events_log"
              WHERE year = ? AND month = ? AND DAY = ? AND properties.browser_bot = false
              GROUP BY properties.browser_name, properties.browser_version, 
                properties.browser_platform_name, properties.browser_platform_version
              ORDER BY total desc
              LIMIT 10
              EOT
}

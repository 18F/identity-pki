locals {
  roles = var.apps_enabled == 1 ? ["app", "idp"] : ["idp"]
}

# ALB tables

resource "aws_glue_catalog_table" "lb_log" {
  for_each      = toset(local.roles)
  name          = "${var.env_name}_${each.value}_lb_logs"
  database_name = aws_athena_database.logs_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                       = "TRUE"
    "parquet.compression"          = "SNAPPY"
    "projection.day.format"        = "yyyy/MM/dd",
    "projection.day.interval"      = "1",
    "projection.day.interval.unit" = "DAYS",
    "projection.day.range"         = "2022/01/01,NOW",
    "projection.day.type"          = "date",
    "projection.enabled"           = "true",
    "storage.location.template" = "s3://login-gov.elb-logs.${data.aws_caller_identity.current.account_id
      }-${var.region}/${var.env_name}/${each.value}/AWSLogs/${data.aws_caller_identity.current.account_id
    }/elasticloadbalancing/${var.region}/$${day}",
    "transient_lastDdlTime" = "1690326639"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location = "s3://login-gov.elb-logs.${data.aws_caller_identity.current.account_id
      }-${var.region}/${var.env_name}/${each.value}/AWSLogs/${data.aws_caller_identity.current.account_id
    }/elasticloadbalancing/${var.region}/$${day}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "regex-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

      parameters = {
        "serialization.format" = 1
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^s]+?)\" \"([^s]+)\" \"([^ ]*)\" \"([^ ]*)\""

      }
    }

    columns {
      name = "type"
      type = "string"
    }

    columns {
      name = "time"
      type = "string"
    }

    columns {
      name = "elb"
      type = "string"
    }

    columns {
      name = "client_ip"
      type = "string"
    }

    columns {
      name = "client_port"
      type = "int"
    }

    columns {
      name = "target_ip"
      type = "string"
    }

    columns {
      name = "target_port"
      type = "int"
    }

    columns {
      name = "request_processing_time"
      type = "double"
    }

    columns {
      name = "target_processing_time"
      type = "double"
    }

    columns {
      name = "response_processing_time"
      type = "double"
    }

    columns {
      name = "elb_status_code"
      type = "int"
    }

    columns {
      name = "target_status_code"
      type = "string"
    }

    columns {
      name = "received_bytes"
      type = "bigint"
    }

    columns {
      name = "sent_bytes"
      type = "bigint"
    }

    columns {
      name = "request_verb"
      type = "string"
    }

    columns {
      name = "request_url"
      type = "string"
    }

    columns {
      name = "request_proto"
      type = "string"
    }

    columns {
      name = "user_agent"
      type = "string"
    }

    columns {
      name = "ssl_cipher"
      type = "string"
    }

    columns {
      name = "ssl_protocol"
      type = "string"
    }

    columns {
      name = "target_group_arn"
      type = "string"
    }

    columns {
      name = "trace_id"
      type = "string"
    }

    columns {
      name = "domain_name"
      type = "string"
    }

    columns {
      name = "chosen_cert_arn"
      type = "string"
    }

    columns {
      name = "matched_rule_priority"
      type = "string"
    }

    columns {
      name = "request_creation_time"
      type = "string"
    }

    columns {
      name = "actions_executed"
      type = "string"
    }

    columns {
      name = "redirect_url"
      type = "string"
    }

    columns {
      name = "lambda_error_reason"
      type = "string"
    }

    columns {
      name = "target_port_list"
      type = "string"
    }

    columns {
      name = "target_status_code_list"
      type = "string"
    }

    columns {
      name = "classification"
      type = "string"
    }

    columns {
      name = "classification_reason"
      type = "string"
    }
  }
}

# PIVCAC table
resource "aws_glue_catalog_table" "pivcac_lb_log" {
  name          = "${var.env_name}_pivcac_lb_logs"
  database_name = aws_athena_database.logs_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                       = "TRUE"
    "parquet.compression"          = "SNAPPY"
    "projection.day.format"        = "yyyy/MM/dd",
    "projection.day.interval"      = "1",
    "projection.day.interval.unit" = "DAYS",
    "projection.day.range"         = "2022/01/01,NOW",
    "projection.day.type"          = "date",
    "projection.enabled"           = "true",
    "storage.location.template" = "s3://login-gov.elb-logs.${data.aws_caller_identity.current.account_id
      }-${var.region}/${var.env_name}/pivcac/AWSLogs/${data.aws_caller_identity.current.account_id
    }/elasticloadbalancing/${var.region}/$${day}",
    "transient_lastDdlTime" = "1690326639"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location = "s3://login-gov.elb-logs.${data.aws_caller_identity.current.account_id
      }-${var.region}/${var.env_name}/pivcac/AWSLogs/${data.aws_caller_identity.current.account_id
    }/elasticloadbalancing/${var.region}/$${day}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "regex-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

      parameters = {
        "serialization.format" = 1
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \\\"([^ ]*) ([^ ]*) (- |[^ ]*)\\\" (\"[^\"]*\") ([A-Z0-9-]+) ([A-Za-z0-9.-]*)$"

      }
    }

    columns {
      name = "elb_name"
      type = "string"
    }

    columns {
      name = "request_ip"
      type = "string"
    }

    columns {
      name = "request_port"
      type = "int"
    }

    columns {
      name = "backend_ip"
      type = "string"
    }

    columns {
      name = "backend_port"
      type = "int"
    }

    columns {
      name = "request_processing_time"
      type = "double"
    }

    columns {
      name = "backend_processing_time"
      type = "double"
    }

    columns {
      name = "client_response_time"
      type = "double"
    }

    columns {
      name = "elb_response_code"
      type = "string"
    }

    columns {
      name = "backend_response_code"
      type = "string"
    }

    columns {
      name = "received_bytes"
      type = "bigint"
    }

    columns {
      name = "sent_bytes"
      type = "bigint"
    }

    columns {
      name = "request_verb"
      type = "string"
    }

    columns {
      name = "url"
      type = "string"
    }

    columns {
      name = "protocol"
      type = "string"
    }

    columns {
      name = "user_agent"
      type = "string"
    }

    columns {
      name = "ssl_cipher"
      type = "string"
    }

    columns {
      name = "ssl_protocol"
      type = "string"
    }


  }
}


# Cloudfront table
resource "aws_glue_catalog_table" "cloudfront_log" {
  name          = "${var.env_name}_cloudfront_logs"
  database_name = aws_athena_database.logs_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL               = "TRUE"
    "ROW FORMAT"           = "DELIMITED"
    "FIELDS TERMINATED BY" = "\t"
  }

  storage_descriptor {
    location = "s3://login-gov.elb-logs.${data.aws_caller_identity.current.account_id
    }-${var.region}/${var.env_name}/cloudfront"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "regex-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

      parameters = {
        "skip.header.line.count" = "2",

      }
    }

    columns {
      name = "date"
      type = "date"
    }

    columns {
      name = "time"
      type = "string"
    }

    columns {
      name = "location"
      type = "string"
    }

    columns {
      name = "bytes"
      type = "bigint"
    }

    columns {
      name = "request_ip"
      type = "string"
    }

    columns {
      name = "method"
      type = "string"
    }

    columns {
      name = "host"
      type = "string"
    }

    columns {
      name = "uri"
      type = "string"
    }

    columns {
      name = "status"
      type = "int"
    }

    columns {
      name = "referrer"
      type = "string"
    }

    columns {
      name = "user_agent"
      type = "string"
    }

    columns {
      name = "query_string"
      type = "string"
    }

    columns {
      name = "cookie"
      type = "string"
    }

    columns {
      name = "result_type"
      type = "string"
    }

    columns {
      name = "request_id"
      type = "string"
    }

    columns {
      name = "host_header"
      type = "string"
    }

    columns {
      name = "request_protocol"
      type = "string"
    }

    columns {
      name = "request_bytes"
      type = "bigint"
    }

    columns {
      name = "time_taken"
      type = "float"
    }

    columns {
      name = "xforwarded_for"
      type = "string"
    }

    columns {
      name = "ssl_protocol"
      type = "string"
    }

    columns {
      name = "ssl_cipher"
      type = "string"
    }

    columns {
      name = "response_result_type"
      type = "string"
    }

    columns {
      name = "http_version"
      type = "string"
    }

    columns {
      name = "fle_status"
      type = "string"
    }

    columns {
      name = "fle_encrypted_fields"
      type = "int"
    }

    columns {
      name = "c_port"
      type = "int"
    }

    columns {
      name = "time_to_first_byte"
      type = "float"
    }

    columns {
      name = "x_edge_detailed_result_type"
      type = "string"
    }

    columns {
      name = "sc_content_type"
      type = "string"
    }

    columns {
      name = "sc_content_len"
      type = "bigint"
    }

    columns {
      name = "sc_range_start"
      type = "bigint"
    }

    columns {
      name = "sc_range_end"
      type = "bigint"
    }


  }
}


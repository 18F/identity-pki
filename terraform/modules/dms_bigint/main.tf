data "aws_s3_object" "ca_certificate_file" {
  bucket = var.cert_bucket
  key    = "ca_certificate_file"
}

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "data_migration_service" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "${var.env_name}-dms-access-for-endpoint"
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.data_migration_service.name
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.data_migration_service.name
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.data_migration_service.name
}

resource "aws_cloudwatch_log_group" "bigint" {
  name              = "${var.env_name}-bigint-tasks"
  retention_in_days = 365
}

resource "aws_dms_certificate" "bigint" {
  certificate_id  = "${var.env_name}-bigint-certificate"
  certificate_pem = data.aws_s3_object.ca_certificate_file.body

  lifecycle {
    ignore_changes = [
      certificate_pem
    ]
  }
}

resource "aws_dms_endpoint" "bigint_source_endpoint" {
  certificate_arn             = aws_dms_certificate.bigint.certificate_arn
  database_name               = "idp"
  endpoint_id                 = "${var.env_name}-bigint-source"
  endpoint_type               = "source"
  engine_name                 = "aurora-postgresql"
  extra_connection_attributes = ""
  kms_key_arn                 = var.rds_kms_key_arn
  password                    = var.rds_password
  port                        = 5432
  server_name                 = var.source_db_address
  ssl_mode                    = "require"
  username                    = var.rds_username
}

resource "aws_dms_endpoint" "bigint_target_endpoint" {
  certificate_arn             = aws_dms_certificate.bigint.certificate_arn
  database_name               = "idp"
  endpoint_id                 = "${var.env_name}-bigint-target"
  endpoint_type               = "target"
  engine_name                 = "aurora-postgresql"
  extra_connection_attributes = ""
  kms_key_arn                 = var.rds_kms_key_arn
  password                    = var.rds_password
  port                        = 5432
  server_name                 = var.target_db_address
  ssl_mode                    = "require"
  username                    = var.rds_username
}

resource "aws_dms_replication_subnet_group" "bigint" {
  replication_subnet_group_description = "${var.env_name} bigint replication subnet group"
  replication_subnet_group_id          = "${var.env_name}-bigint-subnet-group"

  subnet_ids = var.subnet_ids
}

resource "aws_dms_replication_instance" "bigint" {
  allocated_storage            = var.source_db_allocated_storage
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = var.source_db_availability_zone
  engine_version               = "3.4.7"
  kms_key_arn                  = var.rds_kms_key_arn
  multi_az                     = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = false
  replication_instance_class   = replace(var.source_db_instance_class, "db", "dms")
  replication_instance_id      = "${var.env_name}-bigint-replication-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.bigint.id

  vpc_security_group_ids = var.vpc_security_group_ids

}

resource "aws_dms_replication_task" "bigint" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.bigint.replication_instance_arn
  replication_task_id      = "${var.env_name}-bigint-replication-task"
  source_endpoint_arn      = aws_dms_endpoint.bigint_source_endpoint.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.bigint_target_endpoint.endpoint_arn
  replication_task_settings = jsonencode(
    {
      "Logging" : {
        "EnableLogging" : true,
        "LogComponents" : [
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "TRANSFORMATION"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "SOURCE_UNLOAD"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "IO"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "TARGET_LOAD"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "PERFORMANCE"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "SOURCE_CAPTURE"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "SORTER"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "REST_SERVER"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "VALIDATOR_EXT"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "TARGET_APPLY"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "TASK_MANAGER"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "TABLES_MANAGER"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "METADATA_MANAGER"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "FILE_FACTORY"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "COMMON"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "ADDONS"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "DATA_STRUCTURE"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "COMMUNICATION"
          },
          {
            "Severity" : "${var.logger_severity}",
            "Id" : "FILE_TRANSFER"
          }
        ],
      },
      "StreamBufferSettings" : {
        "StreamBufferCount" : 8,
        "CtrlStreamBufferSizeInMB" : 5,
        "StreamBufferSizeInMB" : 8
      },
      "ErrorBehavior" : {
        "FailOnNoTablesCaptured" : true,
        "ApplyErrorUpdatePolicy" : "LOG_ERROR",
        "FailOnTransactionConsistencyBreached" : false,
        "RecoverableErrorThrottlingMax" : 1800,
        "DataErrorEscalationPolicy" : "SUSPEND_TABLE",
        "ApplyErrorEscalationCount" : 0,
        "RecoverableErrorStopRetryAfterThrottlingMax" : true,
        "RecoverableErrorThrottling" : true,
        "ApplyErrorFailOnTruncationDdl" : false,
        "DataTruncationErrorPolicy" : "LOG_ERROR",
        "ApplyErrorInsertPolicy" : "LOG_ERROR",
        "EventErrorPolicy" : "IGNORE",
        "ApplyErrorEscalationPolicy" : "LOG_ERROR",
        "RecoverableErrorCount" : -1,
        "DataErrorEscalationCount" : 0,
        "TableErrorEscalationPolicy" : "STOP_TASK",
        "RecoverableErrorInterval" : 5,
        "ApplyErrorDeletePolicy" : "IGNORE_RECORD",
        "TableErrorEscalationCount" : 0,
        "FullLoadIgnoreConflicts" : true,
        "DataErrorPolicy" : "LOG_ERROR",
        "TableErrorPolicy" : "SUSPEND_TABLE"
      },
      "ValidationSettings" : {
        "ValidationPartialLobSize" : 0,
        "PartitionSize" : 50000,
        "RecordFailureDelayLimitInMinutes" : 0,
        "SkipLobColumns" : false,
        "FailureMaxCount" : 10000,
        "HandleCollationDiff" : false,
        "ValidationQueryCdcDelaySeconds" : 0,
        "ValidationMode" : "ROW_LEVEL",
        "TableFailureMaxCount" : 1000,
        "RecordFailureDelayInMinutes" : 5,
        "MaxKeyColumnSize" : 8096,
        "EnableValidation" : true,
        "ThreadCount" : 16,
        "RecordSuspendDelayInMinutes" : 30,
        "ValidationOnly" : false
      },
      "TTSettings" : {
        "TTS3Settings" : null,
        "TTRecordSettings" : null,
        "EnableTT" : false
      },
      "FullLoadSettings" : {
        "CommitRate" : 100,
        "StopTaskCachedChangesApplied" : false,
        "StopTaskCachedChangesNotApplied" : false,
        "MaxFullLoadSubTasks" : 1,
        "TransactionConsistencyTimeout" : 60,
        "CreatePkAfterFullLoad" : false,
        "TargetTablePrepMode" : "DROP_AND_CREATE"
      },
      "TargetMetadata" : {
        "ParallelApplyBufferSize" : 0,
        "ParallelApplyQueuesPerThread" : 0,
        "ParallelApplyThreads" : 0,
        "TargetSchema" : "",
        "InlineLobMaxSize" : 0,
        "ParallelLoadQueuesPerThread" : 0,
        "SupportLobs" : true,
        "LobChunkSize" : 0,
        "TaskRecoveryTableEnabled" : false,
        "ParallelLoadThreads" : 0,
        "LobMaxSize" : 1024,
        "BatchApplyEnabled" : false,
        "FullLobMode" : false,
        "LimitedSizeLobMode" : true,
        "LoadMaxFileSize" : 0,
        "ParallelLoadBufferSize" : 0
      },
      "BeforeImageSettings" : null,
      "ControlTablesSettings" : {
        "historyTimeslotInMinutes" : 5,
        "HistoryTimeslotInMinutes" : 5,
        "StatusTableEnabled" : false,
        "SuspendedTablesTableEnabled" : false,
        "HistoryTableEnabled" : false,
        "ControlSchema" : "dms_control_tables",
        "FullLoadExceptionTableEnabled" : false
      },
      "LoopbackPreventionSettings" : null,
      "CharacterSetSettings" : null,
      "FailTaskWhenCleanTaskResourceFailed" : false,
      "ChangeProcessingTuning" : {
        "StatementCacheSize" : 50,
        "CommitTimeout" : 1,
        "BatchApplyPreserveTransaction" : true,
        "BatchApplyTimeoutMin" : 1,
        "BatchSplitSize" : 0,
        "BatchApplyTimeoutMax" : 30,
        "MinTransactionSize" : 1000,
        "MemoryKeepTime" : 60,
        "BatchApplyMemoryLimit" : 500,
        "MemoryLimitTotal" : 1024
      },
      "ChangeProcessingDdlHandlingPolicy" : {
        "HandleSourceTableDropped" : true,
        "HandleSourceTableTruncated" : true,
        "HandleSourceTableAltered" : true
      },
      "PostProcessingRules" : null
    }
  )
  table_mappings = jsonencode(
    {
      "rules" : [
        {
          "rule-type" : "selection",
          "rule-id" : "1",
          "rule-name" : "include_all_tables",
          "object-locator" : {
            "schema-name" : "public",
            "table-name" : "%"
          },
          "rule-action" : "include",
          "filters" : []
        },
        {
          "rule-type" : "selection",
          "rule-id" : "4",
          "rule-name" : "exclude_service_providers",
          "object-locator" : {
            "schema-name" : "public",
            "table-name" : "service_providers"
          },
          "rule-action" : "exclude",
          "filters" : []
        },
        {
          "rule-type" : "transformation",
          "rule-id" : "2",
          "rule-name" : "transform_integer_to_bigint",
          "rule-action" : "change-data-type",
          "rule-target" : "column",
          "data-type" : {
            "type" : "int8"
          },
          "object-locator" : {
            "schema-name" : "public",
            "table-name" : "%",
            "column-name" : "%",
            "data-type" : "int4"
          }
        }
      ]
    }
  )
}
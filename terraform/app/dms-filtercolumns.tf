locals {
  transformation_rules = yamldecode(file("./dms-filter-columns-transformation-rules.yml"))
  selection_rules      = yamldecode(file("./dms-filter-columns-selection-rules.yml"))
}

resource "aws_dms_replication_task" "filtercolumns" {
  count                    = var.enable_dms_analytics ? 1 : 0
  migration_type           = "full-load"
  replication_instance_arn = module.dms[count.index].dms_replication_instance_arn
  replication_task_id      = "${var.env_name}-filter-columns-task"
  source_endpoint_arn      = module.dms[count.index].dms_source_endpoint_arn
  target_endpoint_arn      = aws_dms_s3_endpoint.analytics_export[0].endpoint_arn
  replication_task_settings = jsonencode(
    {
      "Logging" : {
        "EnableLogging" : true,
        "EnableLogContext" : false,
        "LogComponents" : [
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "TRANSFORMATION"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "SOURCE_UNLOAD"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "IO"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "TARGET_LOAD"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "PERFORMANCE"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "SOURCE_CAPTURE"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "SORTER"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "REST_SERVER"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "VALIDATOR_EXT"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "TARGET_APPLY"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "TASK_MANAGER"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "TABLES_MANAGER"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "METADATA_MANAGER"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "FILE_FACTORY"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "COMMON"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "ADDONS"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "DATA_STRUCTURE"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "COMMUNICATION"
          },
          {
            "Severity" : "${var.dms_logging_level}",
            "Id" : "FILE_TRANSFER"
          }
        ],
      },
      "StreamBufferSettings" : {
        "StreamBufferCount" : 3,
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
        "EnableValidation" : false,
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
      "rules" : flatten([
        [
          for idx, rule in local.transformation_rules :
          [
            for idx1, column in rule.include_columns :
            {
              "rule-type" : "transformation",
              "rule-id" : "2${format("%04d", idx)}${format("%04d", idx1)}",
              "rule-name" : "transformation-rule-${rule.table}-include-column-${column.name}",
              "rule-target" : "column",
              "object-locator" : {
                "schema-name" : rule.schema,
                "table-name" : rule.table,
                "column-name" : column.name,
              },
              "rule-action" : "include-column",
              "value" : null,
              "old-value" : null
            }
          ]
        ],
        [
          for idx, rule in local.selection_rules :
          {
            "rule-type" : "selection",
            "rule-id" : "1${format("%04d", idx)}",
            "rule-name" : "selection-rule-${idx}-${rule.table}",
            "object-locator" : {
              "schema-name" : rule.schema,
              "table-name" : rule.table,
            },
            "rule-action" : rule.action,
            "filters" : []
          }
        ]
      ])
    }
  )
}
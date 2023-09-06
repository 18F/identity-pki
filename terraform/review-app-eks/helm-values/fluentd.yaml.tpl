enabled: true
#env:
#  - name: FLUENTD_OPT
#    value: "-v"
serviceAccount:
  annotations:
    "eks.amazonaws.com/role-arn": "${fluentd_irsa_iam_role_arn}"
dashboards:
  enabled: "false"
plugins:
  - fluent-plugin-cloudwatch-logs
  - fluent-plugin-prometheus 

configMapConfigs: 
  - fluentd-prometheus-conf

## Fluentd service
service:
  ports: 
    - name: "forwarder"
      protocol: TCP
      containerPort: 24224

fileConfigs:
  01_sources.conf: |-
    <source>
      @type forward
      bind 0.0.0.0
      port 24224
    </source>

  02_filters.conf: |-
        <match kube.app.var.log.containers.**>
          @type  rewrite_tag_filter
          <rule>
            key log
            pattern /[0-9]{4}\\/(0[1-9]|1[0-2])\\/(0[1-9]|[1-2][0-9]|3[0-1]) (2[0-3]|[01][0-9]):[0-5][0-9]:[0-5][0-9] \\[info\\] [1-9][0-9]#\\d+: \\*\\d+ client/
            tag nginx_error.log
          </rule>
          <rule>
            key log
            pattern /events.log/
            tag events.log
          </rule>
          <rule>
           key log
            pattern /workers.log/
            tag workers.log
          </rule>
          <rule>
            key log
            pattern /kms.log/
            tag kms.log
          </rule>
          <rule>
            key log
            pattern /telephony.log/
            tag telephony.log
          </rule>
          <rule>
            key log
            pattern /nginx_access.log/
            tag nginx_access.log
          </rule>
          <rule>
            key log
            pattern /OverallController/
            tag production.log
          </rule>
        </match>

         <filter events.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/srv/idp/shared/log/events.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter kms.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/srv/idp/shared/log/kms.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter workers.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/srv/idp/shared/log/workers.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter telephony.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/srv/idp/shared/log/telephony.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter nginx_access.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/var/log/nginx/access.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter nginx_error.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/var/log/nginx/error.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter production.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}_/srv/pki-rails/shared/log/production.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>

  03_dispatch.conf: |-
      #<label @DISPATCH>
      #  <filter **>
      #    @type prometheus
      #    <metric>
      #      name fluentd_input_status_num_records_total
      #      type counter
      #      desc The total number of incoming records
      #      <labels>
      #        tag $${tag}
      #        hostname $${hostname}
      #      </labels>
      #   </metric>
      # </filter>

      # <match **>
      #   @type relabel
      #   @label @OUTPUT
      # </match>
      #</label>
  04_outputs.conf: |-
    <match events.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match kms.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match workers.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match telephony.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match nginx_access.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match nginx_error.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
    <match production.log>
      @type cloudwatch_logs
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      message_keys log_processed
      remove_log_stream_name_key true
      remove_log_group_name_key true
      auto_create_stream true
    </match>
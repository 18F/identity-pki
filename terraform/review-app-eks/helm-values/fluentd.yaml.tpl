enabled: true
env:
  - name: FLUENTD_OPT
    value: "-v"
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
            pattern /Health/
            tag kms.log
          </rule>
          <rule>
            key log
            pattern /telephony.log/
            tag telephony.log
          </rule>
        </match>

         <filter events.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}/srv/idp/shared/log/events.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter kms.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}/srv/idp/shared/log/kms.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter workers.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}/srv/idp/shared/log/workers.log
            aws_log_stream_name $${record["kubernetes"]["pod_name"]}.$${record["kubernetes"]["labels"]["app.kubernetes.io/name"]}
          </record>
        </filter>
        <filter telephony.log>
          @type record_transformer
          enable_ruby true
          <record>
            aws_log_group_name $${record["kubernetes"]["labels"]["app.kubernetes.io/instance"]}/srv/idp/shared/log/telephony.log
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
    <match events.log kms.log workers.log telephony.log>
      @type cloudwatch_logs
      @id out_cloudwatch_logs_containers
      region "${region}"
      log_group_name_key aws_log_group_name
      log_stream_name_key aws_log_stream_name
      remove_log_stream_name_key true
      remove_log_group_name_key true
      message_keys log_processed
      auto_create_stream true
    </match>
    <match kms.log>
      @type stdout
    </match>
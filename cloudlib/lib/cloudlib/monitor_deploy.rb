# TODO: show metrics prior to deploy start to catch higher order errors (e.g. backwards-incompatible deploy shows similar error rate between new and old because they're incompatible, not because they're safe)
require 'terminal-table'

module Cloudlib
  class MonitorDeploy
    class Deploy
      attr_reader :sha, :min_timestamp, :tag
      attr_accessor :proofing_metrics, :request_metrics, :instance_metrics
      def initialize(sha:, min_timestamp:, tag: nil)
        @sha = sha
        @min_timestamp = min_timestamp
        @tag = tag
        @proofing_metrics = {}
        @request_metrics = {}
        @instance_metrics = {}
      end
    end

    def self.get_and_monitor_deploys(env:, role:)
      deploys = self.get_deploys(env: env, role: role)

      puts 'Found the following deploy(s):'

      deploys.each do |deploy|
        puts
        puts "SHA: #{deploy.sha}"
        puts "Tag: #{deploy.tag}" if deploy.tag
      end
      puts

      if deploys.count < 2
        print 'I need to find at least two, so I will keep looking...'
        while deploys.count < 2
          sleep(1)
          print('.')
          deploys = self.get_deploys(env: env, role: role)
        end

        puts 'Found deploys! They are:'
        deploys.each do |deploy|
          puts
          puts "SHA: #{deploy.sha}"
          puts "Tag: #{deploy.tag}" if deploy.tag
          puts "Start Time: #{deploy.min_timestamp.getlocal.strftime('%I:%M:%S %p')}"
        end
      end

      puts 'Starting to monitor deploy in progress!'
      self.monitor_deploys(deploys: deploys, env: env, role: role)
    end

    def self.get_deploys(env:, role:)
      log_group_name = "#{env}_/srv/#{role}/shared/log/production.log"
      # Find all unique shas/tags in the past hour and the first time a log
      # appeared for them

      query_string = <<~CWQUERY
      fields git_sha, git_tag
      | filter ispresent(status) and ispresent(action)
      | sort @timestamp desc
      | stats min(@timestamp) as min_timestamp, count(*) as count by git_sha, git_tag
      CWQUERY
      start_time = Time.now.utc.to_i - 60*60
      end_time = Time.now.utc.to_i + 60*60
      results = self.query_cloudwatch(log_group_name: log_group_name, start_time: start_time, end_time: end_time, query_string: query_string)

      # Transform [[Aws::CloudWatchLogs::Types::ResultField]] into
      # Deploy objects
      deploys = results.map do |row|
        sha = row.find { |x| x.field == 'git_sha' }&.value
        tag = row.find { |x| x.field == 'git_tag' }&.value
        min_timestamp = row.find { |x| x.field == 'min_timestamp' }&.value
        min_timestamp = Time.parse("#{min_timestamp}Z")

        Deploy.new(sha: sha, tag: tag, min_timestamp: min_timestamp)
      end
    end

    def self.monitor_deploys(deploys:, env:, role:)
      # The SHA that has the most recent minimum timestamp is the new deploy, and represents the
      # start of the deployment process.
      deploys = deploys.sort_by { |x| x.min_timestamp.to_i }
      deploy_start = deploys.last.min_timestamp
      puts "Deploy started at: #{deploy_start.getlocal.strftime('%I:%M:%S %p')} (#{formatted_time_difference(begin_time: deploy_start, end_time: Time.now.utc)})"
      puts

      while true do
        start_time = deploy_start.to_i
        end_time = (Time.now.utc + (1*60*60)).to_i

        deploys = self.get_proofing_metrics(deploys: deploys, env: env, role: role, start_time: start_time, end_time: end_time)
        deploys = self.get_request_metrics(deploys: deploys, env: env, role: role, start_time: start_time, end_time: end_time)
        deploys = self.get_instance_metrics(deploys: deploys, env: env, role: role, start_time: Time.now.utc.to_i - 120, end_time: end_time)
        table_rows = []

        deploys.each_with_index do |deploy, index|
          table_columns = []

          if index == 0
            table_columns << 'Old'
          else
            table_columns << 'New'
          end
          table_columns = table_columns.concat([
            (deploy.sha || deploy.tag), deploy.request_metrics[:five_hundred_percent],
            deploy.request_metrics[:five_hundred_count], deploy.request_metrics[:count],
            deploy.instance_metrics[:instance_count],
            deploy.proofing_metrics[:doc_auth_success_rate],
            deploy.proofing_metrics[:verify_success_rate], deploy.proofing_metrics[:phone_success_rate],
            deploy.proofing_metrics[:proofing_success],
          ])
          table_rows << table_columns
        end
        system('clear')
        puts Terminal::Table.new(headings: ['Age', 'ID', '5XX %', '5XX Count', 'Request Count', 'Instance Count', 'Doc Success %', 'Verify Success %', 'Phone Success %', 'Successful Proofs'], rows: table_rows)

        puts "Deploy duration: #{formatted_time_difference(begin_time: deploys.last.min_timestamp, end_time: Time.now.utc)}"
        puts

        puts 'waiting a bit ...'
        puts
        sleep(15)
      end


      table = Terminal::Table.new :headings => ['Word', 'Number'], :rows => rows
    end

    def self.formatted_time_difference(begin_time:, end_time:)
      time_difference_seconds = (end_time - begin_time).to_i
      hours = time_difference_seconds / 3_600
      minutes = (time_difference_seconds / 60) % 60
      seconds = time_difference_seconds % 60

      time = "#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
      time = "#{hours.to_s.rjust(2, '0')}:#{time}" if hours > 0
      time
    end

    def self.get_instance_metrics(deploys:, env:, role:, start_time:, end_time:)
      instance_query_string = """
      filter ispresent(status) and ispresent(action)
      | stats count(*) by @logStream, git_sha
      """

      rails_log_group_name = "#{env}_/srv/#{role}/shared/log/production.log"
      instance_results = query_cloudwatch(query_string: instance_query_string, log_group_name: rails_log_group_name, start_time: start_time, end_time: end_time)

      deploys.each do |deploy|
        instance_rows = instance_results.filter do |row|
          row.find do |column|
            column.field == 'git_sha' && column.value == deploy.sha
          end || (deploy.sha.nil? && row.all? { |col| col.field != 'git_sha' } )
        end
        instance_metrics = {}
        instance_metrics[:instance_count] = instance_rows.count

        deploy.instance_metrics = instance_metrics
      end

      deploys
    end

    def self.get_request_metrics(deploys:, env:, role:, start_time:, end_time:)
      request_query_string = """
      fields @timestamp, git_sha, (status >= 500) as five_hundred, (status >= 400 and status <= 499) as four_hundred
      | filter ispresent(status) and ispresent(action)
      | stats count(*) as count, sum(five_hundred) as five_hundred_count, (sum(five_hundred)/count(*)) * 100 as five_hundred_percent by git_sha
      """
      rails_log_group_name = "#{env}_/srv/#{role}/shared/log/production.log"

      request_results = query_cloudwatch(query_string: request_query_string, log_group_name: rails_log_group_name, start_time: start_time, end_time: end_time)

      deploys.each do |deploy|
        request_row = request_results.find do |row|
          row.find do |column|
            column.field == 'git_sha' && column.value == deploy.sha
          end || (deploy.sha.nil? && row.all? { |col| col.field != 'git_sha' } )
        end
        request_metrics = {}
        request_metrics[:five_hundred_percent] = request_row&.find { |x| x.field == 'five_hundred_percent' }&.value
        request_metrics[:five_hundred_count] = request_row&.find { |x| x.field == 'five_hundred_count' }&.value
        request_metrics[:count] = request_row&.find { |x| x.field == 'count' }&.value

        deploy.request_metrics = request_metrics
      end

      deploys
    end

    def self.get_proofing_metrics(deploys:, env:, role:, start_time:, end_time:)
      proofing_query_string = """
      fields @timestamp, @message, (name = 'IdV: doc auth image upload vendor submitted') as doc_auth_attempt, (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.success) as doc_auth_success,
      (name = 'IdV: doc auth optional verify_wait submitted') as verify_attempt, (name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.success) as verify_success,
      (name = 'IdV: phone confirmation vendor') as phone_attempt, (name = 'IdV: phone confirmation vendor' and properties.event_properties.success) as phone_success,
      (name = 'IdV: final resolution' and properties.event_properties.success) as proofing_successful
      | filter name in ['IdV: doc auth image upload vendor submitted', 'IdV: phone confirmation vendor', 'IdV: doc auth optional verify_wait submitted', 'IdV: final resolution']
      | stats sum(doc_auth_success)/sum(doc_auth_attempt) * 100 as doc_auth_success_rate, sum(verify_success)/sum(verify_attempt) * 100 as verify_success_rate, sum(phone_success)/sum(phone_attempt) * 100 as phone_success_rate,
        sum(proofing_successful) as proofing_success by properties.git_sha as git_sha
      """

      event_log_group_name = "#{env}_/srv/#{role}/shared/log/events.log"

      proofing_results = query_cloudwatch(query_string: proofing_query_string, log_group_name: event_log_group_name, start_time: start_time, end_time: end_time)
      deploys.each do |deploy|
        proofing_row = proofing_results.find do |row|
          row.find do |column|
            column.field == 'git_sha' && column.value == deploy.sha
          end || (deploy.sha.nil? && row.all? { |col| col.field != 'git_sha' } )
        end
        proofing_metrics = {}
        proofing_metrics[:doc_auth_success_rate] = proofing_row&.find { |x| x.field == 'doc_auth_success_rate' }&.value
        proofing_metrics[:verify_success_rate] = proofing_row&.find { |x| x.field == 'verify_success_rate' }&.value
        proofing_metrics[:phone_success_rate] = proofing_row&.find { |x| x.field == 'phone_success_rate' }&.value
        proofing_metrics[:proofing_success] = proofing_row&.find { |x| x.field == 'proofing_success' }&.value

        deploy.proofing_metrics = proofing_metrics
      end

      deploys
    end

    # Querying CloudWatch is not straight forward, and requires starting an asynchronous query and
    # then polling for a result.
    def self.query_cloudwatch(query_string:, log_group_name:, start_time:, end_time:)
      client = Aws::CloudWatchLogs::Client.new
      results = nil

      query = client.start_query(log_group_name: log_group_name, start_time: start_time, end_time: end_time, query_string: query_string)
      query.on_success do
        query_results = client.get_query_results(query_id: query.query_id)

        query_results.on_success do
          while query_results.status == 'Scheduled' || query_results.status == 'Running'
            sleep(0.5)
            query_results = client.get_query_results(query_id: query.query_id)

            # block will be called when we receive a response, so this effectively blocks
            # until we have an updated status for the running query
            query_results.on_success { }
          end

          results = query_results.results
        end
      end

      results
    end
  end
end

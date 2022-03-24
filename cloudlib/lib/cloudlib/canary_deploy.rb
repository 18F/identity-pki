require 'terminal-table'

module Cloudlib
  # A Deploy represents a single version of a deploy
  class Deploy
    attr_reader :sha, :deploy_time
    attr_accessor :event_metrics, :request_metrics, :instance_metrics, :instance_count
    def initialize(sha:, deploy_time:, instance_count: nil)
      @sha = sha
      @deploy_time = deploy_time
      @instance_count = instance_count

      @event_metrics = {}
      @request_metrics = {}
      @instance_metrics = {}
    end
  end

  # CanaryState enumerates the possible valid states a canary deploy can be in.
  # It is intended to be the more functional state management separate from the
  # AWS APIs used to change the state of a deploy.
  class CanaryState
    attr_accessor :deploys, :has_migrated, :is_migrating, :scheduled_scale_in_exists,
      :is_scaling_new_version_to_full, :all_idps_healthy, :is_scaling_in, :new_sha

    def initialize(deploys:, has_migrated:, is_migrating:, scheduled_scale_in_exists:, is_scaling_new_version_to_full:, all_idps_healthy:, is_scaling_in:, new_sha:)
      @deploys = deploys.sort_by(&:deploy_time)
      @has_migrated = has_migrated
      @is_migrating = is_migrating
      @scheduled_scale_in_exists = scheduled_scale_in_exists
      @is_scaling_new_version_to_full = is_scaling_new_version_to_full
      @all_idps_healthy = all_idps_healthy
      @is_scaling_in = is_scaling_in
      @new_sha = new_sha
    end

    def valid?
      ready_to_start_migrations? ||
        waiting_for_migrations_to_complete? ||
        ready_to_provision_canary_instance_of_new_sha? ||
        waiting_for_canary_instance_to_provision? ||
        monitoring_canary? ||
        waiting_for_scaling_up_new_version? ||
        ready_to_scale_down_old_version? ||
        waiting_for_old_version_to_scale_down? ||
        completed_deploy?
    end

    # If we have 0 or 3+ SHAs deployed, there is a problem
    def invalid_number_of_deploys?
      deploys.count != 1 && deploys.count != 2
    end

    # There is one old version deployed, and migrations have not been started or completed
    def ready_to_start_migrations?
      !is_migrating && !has_migrated && deploys.count == 1 && deploys.first.sha != new_sha
    end

    # There is one old version deployed, and migrations have not been started, but not completed
    def waiting_for_migrations_to_complete?
      is_migrating && !has_migrated && deploys.count == 1 && deploys.first.sha != new_sha
    end

    # Migrations have completed and canary instance has not been started
    def ready_to_provision_canary_instance_of_new_sha?
      has_migrated && deploys.count == 1 && deploys.first.sha != new_sha && !scheduled_scale_in_exists
    end

    # Canary instance has been started but is not serving traffic
    def waiting_for_canary_instance_to_provision?
      has_migrated && deploys.count == 1 && deploys.last.sha != new_sha && scheduled_scale_in_exists
    end

    # Canary instance is serving traffic and we are monitoring metrics to decide whether to roll forward or back
    def monitoring_canary_promotion_status?
      has_migrated && deploys.count == 2 && deploys.last.sha == new_sha && !is_scaling_new_version_to_full && !is_scaling_in
    end

    # Canary instance looked good and we're waiting for all of the new instances to start
    def waiting_for_scaling_up_new_version?
      has_migrated && is_scaling_new_version_to_full && !all_idps_healthy
    end

    # New instances are all healthy and serving traffic, so we can remove old instances
    def ready_to_scale_down_old_version?
      has_migrated && is_scaling_new_version_to_full && all_idps_healthy && !is_scaling_in
    end

    # We have scaled down, and are waiting for old instances to drain and shut down
    def waiting_for_old_version_to_scale_down?
      has_migrated && is_scaling_in && deploys.count == 2
    end

    # New instances are up, and old instances are gone
    def completed_deploy?
      has_migrated && deploys.count == 1 && all_idps_healthy && deploys.first.sha == new_sha
    end

    # Compare old and new deploy metrics to determine whether the new deploy is good or not
    def promotion_status
      raise ArgumentError.new('Invalid number of deploys') if deploys.count != 2
      deploys.sort_by!(&:deploy_time)
      old_deploy = deploys.first
      new_deploy = deploys.last

      new_request_count = new_deploy.request_metrics[:count]
      old_five_hundred_percent = old_deploy.request_metrics[:five_hundred_percent]
      new_five_hundred_percent = new_deploy.request_metrics[:five_hundred_percent]

      if new_request_count > 1000 && new_five_hundred_percent < 0.001 && (new_five_hundred_percent - old_five_hundred_percent).abs < 0.01
        :good
      elsif new_request_count > 1000 && new_five_hundred_percent > 0.01
        :bad
      elsif true
        :not_enough_data
      end
    end
  end

  class CanaryDeploy
    attr_accessor :env, :branch

    def initialize(env:, branch:)
      @env = env
      @branch = branch
    end

    def deploy
      latest_sha = get_most_recent_github_git_sha
      idp_asg_name = "#{env}-idp"
      idpxtra_asg_name = "#{env}-idpxtra"
      worker_asg_name = "#{env}-worker"
      migration_asg_name = "#{env}-migration"
      as = Cloudlib::AutoScaling.new
      idp_asg = as.get_autoscaling_group_by_name(idp_asg_name)

      while true do
        idp_asg = as.get_autoscaling_group_by_name(idp_asg_name)
        raise 'Must have at least two IDPs to do canary deploy' if idp_asg.desired_capacity < 2
        idpxtra_asg = as.get_autoscaling_group_by_name(idpxtra_asg_name)

        deploys = get_deploys
        has_migrated = has_run_migrations?(sha: latest_sha)
        is_migrating = is_running_migrations?(sha: latest_sha)
        scheduled_scale_in = get_scheduled_scale_in
        is_scaling_new_version_to_full = (scheduled_scale_in && (idp_asg.desired_capacity == scheduled_scale_in.desired_capacity * 2))
        health_data = Cloudlib::ElasticLoadBalancingV2.new.find_target_health_data(env, "idp")
        all_idps_healthy = health_data.count { |x| ["healthy", "unused"].include?(x.target_health.state) } == (idp_asg.desired_capacity + idpxtra_asg.desired_capacity)
        is_scaling_in = scheduled_scale_in && idp_asg.desired_capacity == scheduled_scale_in.desired_capacity

        state = CanaryState.new(
          new_sha: latest_sha,
          deploys: deploys,
          has_migrated: has_migrated,
          is_migrating: is_migrating,
          scheduled_scale_in_exists: !scheduled_scale_in.nil?,
          is_scaling_new_version_to_full: is_scaling_new_version_to_full,
          all_idps_healthy: all_idps_healthy,
          is_scaling_in: is_scaling_in,
        )

        if state.invalid_number_of_deploys?
          raise 'bad number of deploys'
        elsif !has_migrated && scheduled_scale_in
          puts 'There is currently a scheduled action to remove old servers as part of a previous deploy'
          puts 'If you have determined it is safe, I can cancel the previous deploy and restart the deployment? (y)'
          should_cancel = STDIN.gets.chomp
          if should_cancel == 'y'
            scheduled_scale_in.delete({auto_scaling_group_name: idp_asg_name})
          else
            puts 'not deleting existing deploy, exiting'
            break
          end
        elsif deploys.count == 2 && !deploys.map(&:sha).include?(latest_sha)
          raise 'bad, two deploys, neither are the most recent'
        elsif deploys.map(&:sha).include?(latest_sha) && !has_migrated
          raise 'bad, new instances that are not migrated'
        elsif state.ready_to_start_migrations?
          puts "#{Time.now}: Ready for migration, recycling one migration instance"
          as.start_recycle("#{env}-migration",
                       new_size: 1,
                       return_to_size: 0,
                       spindown_delay: 900)
          # There is a delay between adding an instance and it being discoverable via AWS APIs,
          # so we manually wait a bit
          sleep(60)
        elsif state.waiting_for_migrations_to_complete?
          print '.'
        elsif state.ready_to_provision_canary_instance_of_new_sha?
          puts "\nMigrated, creating one canary instance with new version, and waiting for it to provision"

          current_size = idp_asg.data.desired_capacity
          as.set_desired_capacity(idp_asg_name, current_size + 1)
          # Schedule a scale down of the IdP far into the future (30 minutes) as a fall back
          as.create_scheduled_action(idp_asg_name, Cloudlib::AutoScaling::RecycleCanaryScheduledActionName, start_time: Time.now + 1_800, desired_capacity: current_size)
        elsif state.waiting_for_canary_instance_to_provision?
          print '.'
        elsif state.monitoring_canary_promotion_status?
          print_deploy_status(deploys: deploys)
          puts "\nCanary in progress, monitoring deploy!"

          case state.promotion_status
          when :good
            puts 'Continue with canary deploy? (yes)'
            input = STDIN.gets.chomp
            if input != 'yes'
              puts 'Continuing to monitor deploy'
              next
            end
            puts 'Scaling up all the way, waiting for new instances to provision'
            idpxtra_asg = as.get_autoscaling_group_by_name(idpxtra_asg_name)
            worker_asg = as.get_autoscaling_group_by_name(worker_asg_name)
            as.set_desired_capacity(idp_asg_name, scheduled_scale_in.desired_capacity * 2)

            as.set_desired_capacity(idpxtra_asg_name, idpxtra_asg.desired_capacity * 2) if idpxtra_asg.desired_capacity > 0
            as.set_desired_capacity(worker_asg_name, worker_asg.desired_capacity * 2) if worker_asg.desired_capacity > 0
          when :not_enough_data
            # wait some more
          when :bad
            # TODO: uh oh, scale down new instances, abort?
          end
        elsif state.waiting_for_scaling_up_new_version?
          print '.'
        elsif state.ready_to_scale_down_old_version?
          puts "\nNew deploy has completed scaling up new servers, starting to scale down old servers"
          idpxtra_asg = as.get_autoscaling_group_by_name(idpxtra_asg_name)
          worker_asg = as.get_autoscaling_group_by_name(worker_asg_name)
          as.set_desired_capacity(idp_asg_name, scheduled_scale_in.desired_capacity)

          as.set_desired_capacity(idpxtra_asg_name, idpxtra_asg.desired_capacity / 2) if idpxtra_asg.desired_capacity > 1
          as.set_desired_capacity(worker_asg_name, worker_asg.desired_capacity / 2) if worker_asg.desired_capacity > 1
          if env == 'prod'
            puts "\n#{Time.now}: To remove old servers, scale-in protection must be removed from idp, idpxtra, and worker instances."
            puts "You will now be prompted to confirm removing scale-in protection from all of the instance types."
            Cloudlib::AutoScaling.new.scale_in_instances("prod-idp", {})
            Cloudlib::AutoScaling.new.scale_in_instances("prod-idpxtra", {})
            Cloudlib::AutoScaling.new.scale_in_instances("prod-worker", {})
          end

          puts 'Started scaling down old servers, waiting for old servers to drain and terminate'
        elsif state.waiting_for_old_version_to_scale_down?
          print '.'
        elsif state.completed_deploy?
          puts "\n#{Time.now}: Done!"
          scheduled_scale_in.delete({auto_scaling_group_name: idp_asg_name}) if scheduled_scale_in
          as.set_desired_capacity(migration_asg_name, 0)
          exit 0
        else
          raise 'uhoh'
        end

        sleep(4)
      end
    end

    def update_deploy_metrics!(deploys:)
      start_time = deploys.last.deploy_time.to_i
      end_time = Time.now.utc.to_i + 60*60
      deploys = get_event_metrics(deploys: deploys, start_time: start_time, end_time: end_time)
      deploys = get_request_metrics(deploys: deploys, start_time: start_time, end_time: end_time)
    end

    def print_deploy_status(deploys:)
      table_rows = []

      deploys.each_with_index do |deploy, index|
        table_columns = []

        if index == 0
          table_columns << "Old - #{deploy.sha.slice(0, 8)}"
        else
          table_columns << "New - #{deploy.sha.slice(0, 8)}"
        end

        table_columns = table_columns.concat([
          deploy.request_metrics[:five_hundred_percent],
          deploy.request_metrics[:five_hundred_count], deploy.request_metrics[:count],
          deploy.event_metrics[:doc_auth_success_percent],
          deploy.event_metrics[:verify_success_percent], deploy.event_metrics[:phone_proof_success_percent],
          deploy.event_metrics[:proofing_success],
          deploy.event_metrics[:two_fa_success_percent]
        ])
        table_rows << table_columns
      end
      system('clear')
      puts Terminal::Table.new(headings: ['ID', '5XX %', '5XX Count', 'Request Count', 'Doc Success %', 'Verify Success %', 'Phone Proof Success %', 'Successful Proofs', '2FA Success %'], rows: table_rows)
    end

    def is_running_migrations?(sha:)
      ec2 = Cloudlib::EC2.new(env: env)
      begin
        instances = ec2.list_instances_by_name(['*migration'], in_vpc: true, states: ['pending', 'running'])
        instances.any? { |x| [nil, sha].include?(x.tags.find { |y| y.key == 'gitsha:idp' }&.value) }
      rescue Cloudlib::NotFound => e
        false
      end
    end

    def get_deploys
      # potential states: pending  running  rebooting  stopping  stopped  shutting-down
      ec2 = Cloudlib::EC2.new(env: env)
      instances = ec2.list_instances_by_name(['*idp'], in_vpc: true, states: ['pending', 'running'])
      deploys = instances.group_by { |x| x.tags.find { |y| y.key == 'gitsha:idp' }&.value }.map do |sha, instance_group|
        next if sha.nil?
        start_time = instance_group.sort_by { |x| x.launch_time }.first.launch_time
        Deploy.new(sha: sha, deploy_time: start_time, instance_count: instance_group.count)
      end.compact.sort_by(&:deploy_time)

      if deploys.count > 1
        update_deploy_metrics!(deploys: deploys)
      end

      deploys
    end

    def get_scheduled_scale_in
      as = Cloudlib::AutoScaling.new
      scheduled_actions = as.get_autoscaling_scheduled_actions("#{env}-idp")
      scheduled_actions.find { |action| action.name == Cloudlib::AutoScaling::RecycleCanaryScheduledActionName }
    end

    def get_most_recent_github_git_sha
      `git ls-remote https://github.com/18F/identity-idp.git #{branch} | awk '{print $1}'`.chomp
    end

    def has_run_migrations?(sha:)
      s3 = Aws::S3::Resource.new(
        region: 'us-west-2',
      )

      bucket =  s3.bucket(artifacts_bucket)

      file = "#{env}/#{sha}.idp.tar.gz"
      bucket.object(file).exists?
    end


    def artifacts_bucket
      @account_id ||= begin
        JSON.parse(`aws sts get-caller-identity`)['Account']
      rescue JSON::ParserError
        nil
      end

      if !@account_id || @account_id.empty?
        STDERR.puts "#{basename}: could not detect bucket, check AWS_VAULT or AWS_PROFILE env vars"
        exit 1
      end

      "login-gov.app-artifacts.#{@account_id}-us-west-2"
    end

    def get_request_metrics(deploys:, start_time:, end_time:)
      request_query_string = <<~CW
      fields @timestamp, git_sha, (status >= 500) as five_hundred, (status >= 400 and status <= 499) as four_hundred
      | filter ispresent(status) and ispresent(action) and git_sha like /(#{deploys.map {|x| "#{x.sha.slice(0, 8)}"}.join('|')})/
      | stats count(*) as count, sum(five_hundred) as five_hundred_count, (sum(five_hundred)/count(*)) * 100 as five_hundred_percent by git_sha
      CW
      rails_log_group_name = "#{env}_/srv/idp/shared/log/production.log"

      request_results = CanaryDeploy.query_cloudwatch(query_string: request_query_string, log_group_name: rails_log_group_name, start_time: start_time, end_time: end_time)

      deploys.each do |deploy|
        request_row = request_results.find do |row|
          row.find do |column|
            column.field == 'git_sha' && deploy.sha.match?(column.value)
          end
        end
        request_metrics = {}
        request_metrics[:five_hundred_percent] = request_row&.find { |x| x.field == 'five_hundred_percent' }&.value || 0.0
        request_metrics[:five_hundred_percent] = Float(request_metrics[:five_hundred_percent])

        request_metrics[:five_hundred_count] = request_row&.find { |x| x.field == 'five_hundred_count' }&.value || 0
        request_metrics[:five_hundred_count] = Integer(request_metrics[:five_hundred_count])
        request_metrics[:count] = request_row&.find { |x| x.field == 'count' }&.value || 0
        request_metrics[:count] = Integer(request_metrics[:count])

        deploy.request_metrics = request_metrics
      end

      deploys
    end

    def get_event_metrics(deploys:, start_time:, end_time:)
      event_query_string = <<~CW
      fields @timestamp, @message, (name = 'IdV: doc auth image upload vendor submitted') as doc_auth_attempt, (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.success) as doc_auth_success,
      (name = 'IdV: doc auth optional verify_wait submitted') as verify_attempt, (name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.success) as verify_success,
      (name = 'IdV: phone confirmation vendor') as phone_proof_attempt, (name = 'IdV: phone confirmation vendor' and properties.event_properties.success) as phone_proof_success,
      (name = 'IdV: final resolution' and properties.event_properties.success) as proofing_successful, (name = 'Multi-Factor Authentication') as two_fa_attempt,
      ((name = 'Multi-Factor Authentication') and properties.event_properties.success) as two_fa_success
      | filter name in ['IdV: doc auth image upload vendor submitted', 'IdV: phone confirmation vendor', 'IdV: doc auth optional verify_wait submitted', 'IdV: final resolution', 'Multi-Factor Authentication'] and properties.git_sha like /(#{deploys.map {|x| "#{x.sha.slice(0, 8)}"}.join('|')})/
      | stats sum(doc_auth_success)/sum(doc_auth_attempt) * 100 as doc_auth_success_percent, sum(verify_success)/sum(verify_attempt) * 100 as verify_success_percent, sum(phone_proof_success)/sum(phone_proof_attempt) * 100 as phone_proof_success_percent,
        sum(proofing_successful) as proofing_success, sum(two_fa_success)/sum(two_fa_attempt) * 100 as two_fa_success_percent by properties.git_sha as git_sha
      CW

      event_log_group_name = "#{env}_/srv/idp/shared/log/events.log"

      event_results = CanaryDeploy.query_cloudwatch(query_string: event_query_string, log_group_name: event_log_group_name, start_time: start_time, end_time: end_time)
      deploys.each do |deploy|
        event_row = event_results.find do |row|
          row.find do |column|
            column.field == 'git_sha' && deploy.sha.match?(column.value)
          end
        end
        event_metrics = {}
        event_metrics[:doc_auth_success_percent] = event_row&.find { |x| x.field == 'doc_auth_success_percent' }&.value
        event_metrics[:doc_auth_success_percent] = event_metrics[:doc_auth_success_percent] && Float(event_metrics[:doc_auth_success_percent])

        event_metrics[:verify_success_percent] = event_row&.find { |x| x.field == 'verify_success_percent' }&.value
        event_metrics[:verify_success_percent] = event_metrics[:verify_success_percent] && Float(event_metrics[:verify_success_percent])

        event_metrics[:phone_proof_success_percent] = event_row&.find { |x| x.field == 'phone_proof_success_percent' }&.value
        event_metrics[:phone_proof_success_percent] = event_metrics[:phone_proof_success_percent] && Float(event_metrics[:phone_proof_success_percent])

        event_metrics[:two_fa_success_percent] = event_row&.find { |x| x.field == 'two_fa_success_percent' }&.value
        event_metrics[:two_fa_success_percent] = event_metrics[:two_fa_success_percent] && Float(event_metrics[:two_fa_success_percent])

        event_metrics[:proofing_success] = Integer(event_row&.find { |x| x.field == 'proofing_success' }&.value || 0)

        deploy.event_metrics = event_metrics
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

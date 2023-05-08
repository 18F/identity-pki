# frozen_string_literal: true

require 'logger'
require 'set'
require 'yaml'

require 'aws-sdk-iam'
require 'aws-sdk-ses'
require 'aws-sdk-sts'

module IdentityAudit

  # Class for auditing AWS users and keys
  class AwsIamAuditor < Functions::AbstractLambdaHandler

    # Make this accessible via CLI
    Functions.register_handler(self, 'audit-aws')

    AccessKeyAgeWarnDays = 180 # 6 months

    attr_reader :aws_account_id
    attr_reader :default_email_domain
    attr_reader :group_email_address
    attr_reader :iam, :iam_r
    attr_reader :ses

    def initialize(log_level: Logger::INFO, dry_run: true)
      super

      begin
        @ses = Aws::SES::Client.new
      rescue StandardError
        log.error('Failed to create SES client. Do you have AWS creds?')
        raise
      end

      @audit_config = team_data.fetch('audit_config').fetch('aws')
      @iam_r = Aws::IAM::Resource.new
      @iam = @iam_r.client

      @aws_account_id = get_aws_account_id

      @default_email_domain = @audit_config.fetch('default_email_domain')

      @group_email_address = @audit_config.fetch('group_cc_address')
    end

    # This is the main CLI handler function
    #
    # @see #run_audit
    #
    # @return [String]
    #
    def cli_main(_args)
      run_audit
    end

    # This is the main lambda handler function
    #
    # @see #run_audit
    #
    # @return [String]
    #
    def lambda_main(event:, context:)
      _ = event, context # discard args
      run_audit
    end

    def from_address
      return @from_address if @from_address

      mapping = @audit_config.fetch('per_account_from_address')
      begin
        @from_address = mapping.fetch(aws_account_id)
      rescue KeyError
        log.error('Could not find AWS account in team.yml map')
        log.error("per_account_from_address: #{mapping.inspect}")
        log.error("AWS account ID: #{aws_account_id.inspect}")
        raise
      end

      @from_address
    end

    def get_aws_account_id
      Aws::STS::Client.new.get_caller_identity.account
    end

    # Get and cache team data from team.yml in github
    def team_data
      @team_data ||= team_data!
    end

    # Retrieve new team data from team.yml in github
    def team_data!
      log.info('Fetching team.yml from repo')
      raw = RepoContent.read_team_yml_using_config
      YAML.safe_load(raw)
    end

    def get_team_members
      team_data.fetch('team_members')
    end

    def get_alumni
      team_data.fetch('alumni')
    end

    def get_machine_users
      @audit_config.fetch('machine_users', [])
    end

    # @return [Set<String>]
    def yml_team_aws_users
      @yml_team_aws_users ||= make_aws_user_map(get_team_members)
    end

    # @return [Set<String>]
    def yml_alumni_aws_users
      @yml_alumni_aws_users ||= make_aws_user_map(get_alumni,
                                                  log_on_missing: false)
    end

    def yml_machine_users
      @yml_machine_users ||= Set.new(get_machine_users)
    end

    # Run get_aws_username for an array of user hashes and return a mapping from
    # AWS username to user hash.
    #
    # @param user_array [Array<Hash>]
    #
    # @see #get_aws_username
    #
    # @return [Hash<String, Hash>]
    #
    def make_aws_user_map(user_array, log_on_missing: true)
      mapping = {}
      user_array.each do |u_hash|
        username = get_aws_username(u_hash, log_on_missing: log_on_missing)
        next unless username

        mapping[username] = u_hash
      end

      mapping
    end

    # Given a user hash, return the AWS username for that user. If user as an
    # explicit "aws" key, just return that. If there is an email address with
    # the default_email_domain, use that username as the username. Otherwise
    # skip the user and log an error if log_on_missing is set.
    #
    # @param user_hash [Hash]
    # @param log_on_missing [Boolean]
    #
    # @return [String]
    #
    def get_aws_username(user_hash, log_on_missing: true)
      if user_hash.has_key?('aws')
        user_hash.fetch('aws').downcase
      else
        begin
          from_email = find_username_from_email_address(user_hash)
        rescue KeyError
          raise if log_on_missing
        end
        if from_email
          from_email.downcase
        else
          if log_on_missing
            enqueue_report('Could not infer AWS username for ' +
                           user_hash.inspect)
          end
          nil
        end
      end
    end

    # Given a hash of user data, find any email addresses that end with the
    # default email domain. If any are found, return the username.
    # So for example, if "example.com" is the default domain, and the user hash
    # contains "email: jane.doe@example.com", then return "jane.doe".
    #
    # @param [Hash] user_hash
    # @return [String, nil] Either a string username or nil.
    #
    def find_username_from_email_address(user_hash)
      emails = Array(user_hash.fetch('email'))
      default_email = emails.find { |e|
        e.end_with?('@' + default_email_domain)
      }
      if default_email
        return default_email[0..(-default_email_domain.length - 2)]
      end

      nil
    end

    # List the IAM users in AWS and return an array of them as objects.
    #
    # @return [Array<Aws::IAM::User>]
    def iam_list_users
      iam_r.users.to_a
    end

    # Top level method for running audits, invoked by CLI or Lambda.
    #
    # @return [String]
    def run_audit
      log.info('run_audit()')
      @reports = []

      if ENV['PRY_DEBUG']
        # rubocop:disable Lint/Debugger
        require 'pry'
        binding.pry
        # rubocop:enable Lint/Debugger
      end

      log.info("Auditing AWS users in account #{get_aws_account_id}")

      audit_aws_users

      send_final_report
    end

    def enqueue_report(report)
      log.warn(report)
      @reports << report
    end

    # @return [String]
    def send_final_report
      if @reports.empty?
        log.info('All audits were clean!')
        return 'All audits were clean!'
      end

      log.warn('Some audits failed')

      resp = send_raw_email(
        to_email: group_email_address, send_cc: false,
        subject: "[audit-aws] Report for #{aws_account_id}",
        body: <<~EOM
          Report from audit-aws in AWS account #{aws_account_id}:

          #{@reports.join("\n")}

          Cheers,
          The audit-aws bot
        EOM
      )

      resp.fetch(:raw_email)
    end

    # Main method for running AWS audits.
    #
    # @return [Boolean] Whether all audits returned clean.
    def audit_aws_users
      iam_list_users.each do |u|
        team_yml_ok, u_yml_data = check_team_yml(u)
        next unless team_yml_ok

        check_password(u, u_yml_data)
        check_keys(u, u_yml_data)
      end
    end

    # @param [Aws::IAM::User] user
    # @return [Array{Boolean, Hash}] A 2-element array. First element: whether
    #   the user can be found in team.yml. Second element: hash of data for the
    #   user from team.yml.
    def check_team_yml(user)
      if yml_team_aws_users.include?(user.user_name)
        return true, yml_team_aws_users.fetch(user.user_name)
      end

      if yml_alumni_aws_users.include?(user.user_name)
        enqueue_report("Found alum #{user.user_name} still has access!")
        return false, yml_alumni_aws_users.fetch(user.user_name)
      end

      if yml_machine_users.include?(user.user_name)
        log.debug("Found #{user.user_name} among team.yml machine_users")
        return true, :machine_user
      end

      enqueue_report("Unknown user #{user.user_name} has access to AWS")
      [false, nil]
    end

    # @param [Aws::IAM::User] user
    # @param [Hash] user_yml_data Data for user from team.yml
    # @return [Boolean]
    def check_password(user, user_yml_data)
      expect_password = !yml_machine_users.include?(user.user_name)

      # the LoginProfile#exists? method seems to be gone in aws-sdk 2.0
      begin
        user.login_profile.data
      rescue Aws::IAM::Errors::NoSuchEntity
        if expect_password
          log.info("User #{user.user_name} has no password access to console")
        end
        return true
      end

      if user.mfa_devices.count == 0
        enqueue_report("User #{user.user_name} has no MFA devices")
        send_email_mfa_notice(user, user_yml_data)
        return false
      end

      unless expect_password
        enqueue_report(
          "User #{user.user_name} has unexpected password console access")
        return false
      end
    end

    # @param [Aws::IAM::User] user
    # @param [Hash] user_yml_data Data for user from team.yml
    #
    def check_keys(user, user_yml_data)
      user.access_keys.each do |k|
        age_days = ((Time.now.utc - k.create_date) / 3600 / 24).round
        next if age_days <= AccessKeyAgeWarnDays

        enqueue_report(
          "User #{user.user_name} has access key #{k.access_key_id}" \
          " created #{age_days} days ago, needs rotation"
        )
        send_email_key_rotation(user, user_yml_data,
                                desc: k.access_key_id, days: age_days)
      end

      user.signing_certificates.each do |k|
        age_days = ((Time.now.utc - k.upload_date) / 3600 / 24).round
        next if age_days <= AccessKeyAgeWarnDays

        enqueue_report(
          "User #{user.user_name} has certificate #{k.certificate_id}" \
          " created #{age_days} days ago, needs rotation"
        )
        send_email_key_rotation(user, user_yml_data,
                                desc: k.certificate_id, days: age_days)
      end
    end

    # Send an email notice to users whose keys need rotation.
    def send_email_key_rotation(user, user_hash, desc:, days:)
      # don't email machine users
      if user_hash == :machine_user
        log.info("Skipping email to #{user.user_name}, machine user")
        return
      end

      send_user_email(user_hash, '[audit-aws] Please rotate your AWS API keys',
                      <<~EOM
          Hello #{user_hash.fetch('name').split(' ').first},

          The following AWS API key of yours is old and should be rotated at
          your convenience:

          #{desc}, created #{days} days ago.

          The warning threshold is #{AccessKeyAgeWarnDays} days.

          User: #{user.arn}

          Thanks!
          The audit-aws bot
        EOM
      )
    end

    # Send an email/slack notice to users without MFA
    def send_email_mfa_notice(user, user_hash)
      # don't email machine users
      if user_hash == :machine_user
        log.info("Skipping email to #{user.user_name}, machine user")
        return
      end

      send_user_email(user_hash, '[audit-aws] Urgent: please add MFA to AWS',
                      <<~EOM
          Hello #{user_hash.fetch('name').split(' ').first},

          You have an AWS account that does not have two-factor authentication
          enabled. Please enable MFA as soon as possible!

          User: #{user.arn}

          Thanks!
          The audit-aws bot
        EOM
      )
    end

    def send_user_email(user_hash, subject, body)
      log.debug("Sending email to #{user_hash.fetch('name').inspect}")
      email = Array(user_hash.fetch('email')).fetch(0)
      send_raw_email(to_email: email, subject: subject, body: body,
                     send_cc: true)
    end

    def send_raw_email(to_email:, subject:, body:, send_cc: true)
      log.info((dry_run? ? '[DRY RUN] ' : '') +
               "send_email: #{to_email.inspect}, #{subject.inspect}, " +
               "#{body.length} chars body")

      raw_email = <<~EOM
        From: #{from_address}
        To: #{to_email}
        Cc: #{send_cc ? group_email_address : ''}
        Subject: #{subject}

        #{body}
      EOM

      if dry_run?
        log.info('[DRY RUN] Would have sent email:')
        log.info("\n[DRY RUN]:\n" + raw_email.gsub(/^/, '    '))
        return { ses_response: nil, raw_email: raw_email }
      else
        log.debug(raw_email)
      end

      response = ses.send_raw_email(raw_message: { data: raw_email })

      log.debug("Sent email with message ID #{response.message_id}")

      { ses_response: response, raw_email: raw_email }
    end
  end
end

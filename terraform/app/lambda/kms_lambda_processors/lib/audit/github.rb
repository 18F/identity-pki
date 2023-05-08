# frozen_string_literal: true

require 'json'
require 'logger'
require 'yaml'

require 'aws-sdk-secretsmanager'
require 'aws-sdk-ses'
require 'octokit'

module IdentityAudit

  # Auditor of github teams and membership
  #
  # This script requires a Github access token with the `read:org` scope on the
  # organization you wish to audit.
  # Generate the ACCESS_TOKEN at https://github.com/settings/tokens/new
  #
  class GithubAuditor < Functions::AbstractLambdaHandler
    attr_reader :ok
    attr_reader :ses
    attr_reader :lambda_config

    # Make this accessible via CLI
    Functions.register_handler(self, 'audit-github')

    def initialize(log_level: Logger::INFO, dry_run: true)
      super

      begin
        @ses = Aws::SES::Client.new
      rescue StandardError
        log.error('Failed to create SES client. Do you have AWS creds?')
        raise
      end

      @lambda_config = IdentityAudit::Config.new.data

      @ok = new_octokit_client(token: retrieve_github_access_token)
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

    def audit_config
      team_data.fetch('audit_config').fetch('github')
    end

    def email_from_address
      audit_config.fetch('email_report').fetch('from')
    end

    def email_to_address
      audit_config.fetch('email_report').fetch('to')
    end

    def new_octokit_client(token: nil, netrc_file: nil)
      if token
        log.debug("New Octokit client using access token, len #{token.length}")
        Octokit::Client.new(access_token: token, auto_paginate: true)
      elsif netrc_file
        log.debug("New Octokit client using netrc file: #{netrc_file.inspect}")
        Octokit::Client.new(netrc: true, netrc_file: netrc_file,
                            auto_paginate: true)
      else
        raise ArgumentError.new('Must pass token or netrc_file')
      end
    end

    # @return [Set<String>]
    def yml_team_github_usernames
      @yml_team_github_usernames ||= Set.new(
        team_data.fetch('team_members').map { |m| m.fetch('github') }.compact
          .map(&:downcase)
      )
    end

    # @return [Set<String>]
    def yml_alumni_github_usernames
      @yml_alumni_github_usernames ||= Set.new(
        team_data.fetch('alumni').map { |m| m['github'] }.compact
          .map(&:downcase)
      )
    end

    def get_core_team_name
      parts = audit_config.fetch('core_team')
      if parts.length != 2
        raise 'Expected core_team to contain 2 parts (org, team name)'
      end

      parts
    end

    def get_yml_team_name
      parts = audit_config.fetch('team_yml_team')
      if parts.length != 2
        raise 'Expected team_yml_team to contain 2 parts (org, team name)'
      end

      parts
    end

    def get_org_teams(org)
      ok.org_teams(org)
    end

    def get_team_by_name(org, team_name)
      team = get_org_teams(org).find { |t| t.name == team_name }

      unless team
        raise KeyError.new(
          "No team found named #{team_name.inspect} in #{org.inspect}")
      end

      team
    end

    def get_team_id(org, team_name)
      get_team_by_name(org, team_name).id
    end

    # Get the child Github teams of the given team ID.
    #
    # @param team_id [Integer]
    def get_child_teams(team_id)
      # suppress annoying preview message
      accept_header = Octokit::Preview::PREVIEW_TYPES.fetch(:nested_teams)

      ok.child_teams(team_id, accept: accept_header)
    end

    def team_members(team_id)
      log.debug("Looking up team members of team ID #{team_id.inspect}")
      ok.team_members(team_id)
    end

    def team_members_by_name(org, team_name)
      team_members(get_team_id(org, team_name))
    end

    def recursive_team_members_by_name(org, team_name)
      root = get_team_by_name(org, team_name)

      all_teams = teams_under(team_obj: root)

      all_members = all_teams.flat_map { |t| team_members(t.id) }

      # dedup by login
      uniq_by(all_members, :login)
    end

    # Default path in AWS Secrets Manager where the github access token can be
    # found. Override in config.json.
    def secret_id_for_github_token
      lambda_config.fetch('identity-audit')
                   .fetch('secret_id_for_github_access_token')
    end

    def retrieve_github_access_token
      log.debug('Fetching github access token from AWS SM at ' +
                secret_id_for_github_token.inspect)
      sm = Aws::SecretsManager::Client.new
      data = sm.get_secret_value(secret_id: secret_id_for_github_token)
               .secret_string
      log.debug("Retrieved #{data.bytesize} bytes")

      JSON.parse(data).fetch('access_token')
    end

    def team_tree(team_obj:)
      children = get_child_teams(team_obj.id)

      # recurse
      children.map! { |c| team_tree(team_obj: c) }

      {
        team_obj => children,
      }
    end

    def teams_under(team_obj:, verbose: true)
      if verbose
        log.debug("Looking up Github teams under #{team_obj.name.inspect}")
      end
      teams = [team_obj]

      children = get_child_teams(team_obj.id)

      # recurse
      teams.concat(children.flat_map { |c|
        teams_under(team_obj: c, verbose: false)
      })

      teams
    end

    def pretty_tree(tree:)
      out = {}
      tree.each_pair { |k, v|
        out[k.name] = v.map { |t| pretty_tree(tree: t) }
      }

      if out.length == 1 && out.values.flatten.empty?
        out = out.keys.first
      end

      out
    end

    # @return [String] audit report
    def run_audit
      log.info('run_audit()')
      @reports = []

      if ENV['PRY_DEBUG']
        # rubocop:disable Lint/Debugger
        require 'pry'
        binding.pry
        # rubocop:enable Lint/Debugger
      end

      audit_core_teams
      audit_recursive_yml_team

      send_final_report
    end

    def enqueue_report(report)
      log.warn(report)
      @reports << report
    end

    def send_final_report
      if @reports.empty?
        log.info('All audits were clean!')
        return
      end

      log.warn('Some audits failed')

      resp = send_raw_email(to_email: email_to_address,
                            subject: 'audit-github report',
                            body: <<~EOM
        Report from audit-github:

        #{@reports.join("\n")}

        Cheers,
        The audit-github bot
      EOM
      )

      resp.fetch(:raw_email)
    end

    def send_raw_email(to_email:, subject:, body:)
      log.info("send_email: #{to_email.inspect}, #{subject.inspect}, " \
               "#{body.length} chars body")

      raw_email = <<~EOM
        From: #{email_from_address}
        To: #{to_email}
        Subject: #{subject}

        #{body}
      EOM

      if dry_run?
        log.info('[DRY RUN] Would have sent email:')
        log.info("[DRY RUN]\n" + raw_email.gsub(/^/, '    '))
        return { ses_response: nil, raw_email: raw_email }
      else
        log.debug(raw_email)
      end

      response = ses.send_raw_email(raw_message: { data: raw_email })

      log.debug("Sent email with message ID #{response.message_id}")

      { ses_response: response, raw_email: raw_email }
    end

    # All team.yml users should be a part of one or both of the core_team and
    # the team_yml_team.
    def audit_core_teams
      expected = yml_team_github_usernames

      core_team_org, core_team_name = get_core_team_name
      gh_core_members = team_members_by_name(core_team_org, core_team_name)

      yml_team_org, yml_team_name = get_yml_team_name
      gh_yml_members = team_members_by_name(yml_team_org, yml_team_name)

      # check for extra users
      audit_generic_team('audit_core_teams', core_team_name, gh_core_members,
                         expected, check_missing: false)
      audit_generic_team('audit_core_teams', yml_team_name, gh_yml_members,
                         expected, check_missing: false)

      # check for missing users
      actual_team_set = (gh_core_members + gh_yml_members
        ).map(&:login).map(&:downcase).to_set

      unexpected_lack_access = expected - actual_team_set
      unexpected_lack_access.each do |u|
        enqueue_report("audit_core_teams: [lack-access] #{u.inspect} is in " +
                       "team.yml but not #{core_team_name} or #{yml_team_name}")
      end
    end

    def audit_recursive_yml_team
      core_team_org, core_team_name = get_yml_team_name
      github_team = recursive_team_members_by_name(core_team_org,
                                                   core_team_name)
      expected = yml_team_github_usernames
      audit_generic_team('audit_recursive_yml_team', core_team_name,
                         github_team, expected)
    end

    # @param [Array<Sawyer::Resource>] team_member_objs A list of team member
    #   objects returned by the GitHub API to Octokit
    # @param [Set<String>] expected_team_set The expected list of github
    #   usernames that should have access
    # @param [String] label A label for this check for printed output
    # @param [Boolean] check_missing Whether to check for expected users missing
    #   from the team
    def audit_generic_team(label, team_name, team_member_objs,
                           expected_team_set, check_missing: true)
      actual_team_set = team_member_objs.map(&:login).map(&:downcase).to_set

      unexpected_have_access = actual_team_set - expected_team_set
      unexpected_lack_access = expected_team_set - actual_team_set

      # Override lack_access to nothing if check_missing is false
      unless check_missing
        unexpected_lack_access = []
      end

      if unexpected_have_access.empty? && unexpected_lack_access.empty?
        log.info("#{label}: OK")
        return
      end

      unexpected_have_access.each do |u|
        enqueue_report("#{label}: [extra-access] #{u.inspect} " +
                       "has access to #{team_name} but is not in team.yml")
      end

      unexpected_lack_access.each do |u|
        enqueue_report("#{label}: [lack-access] #{u.inspect} " +
                       "is in team.yml but not #{team_name}")
      end

      return [unexpected_have_access, unexpected_lack_access]
    end

    def uniq_by(enumerable, attr)
      enumerable.each_with_object({}) { |e, h|
        h[e.public_send(attr)] = e
      }.values
    end
  end
end

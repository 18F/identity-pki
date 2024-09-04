#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'aws-sdk-redshiftdataapiservice'
require 'aws-sdk-secretsmanager'
require 'logger'
require 'optparse'

# Quotes single strings and arrays of strings for SQL
# @example
#   quote("foo")
#   => "'foo'"
#   quote(["foo", "bar"])
#   => "('foo', 'bar')"
# @param [String, Array<String>] val
# @return [String]
def quote(val)
  if val.is_a?(Array)
    "(#{val.map { |v| quote(v) }.join(', ')})"
  else
    %('#{val}')
  end
end

def env_name
  @env_name ||= File.read('/etc/login.gov/info/env').chomp
end

def instance_credentials
  @instance_credentials ||= Aws::InstanceProfileCredentials.new
end

def secret_arn
  @secret_arn ||= Aws::SecretsManager::Client.new(region: 'us-west-2')
                                             .describe_secret(secret_id: "redshift/#{env_name}-analytics-superuser")
                                             .arn
end

def redshift_data_client
  @redshift_data_client ||= Aws::RedshiftDataAPIService::Client.new(
    credentials: instance_credentials
  )
end

def user_groups
  [
    {
      'name' => 'lg_users',
      'schemas' => [
        {
          'schema_name' => 'idp',
          'schema_privileges' => 'USAGE',
          'table_privileges' => 'SELECT',
        },
        {
          'schema_name' => 'logs',
          'schema_privileges' => 'USAGE',
          'table_privileges' => 'SELECT',
        },
      ],
    },
    {
      'name' => 'lg_admins',
      'schemas' => [
        {
          'schema_name' => 'idp',
          'schema_privileges' => 'ALL PRIVILEGES',
          'table_privileges' => 'ALL PRIVILEGES',
        },
        {
          'schema_name' => 'logs',
          'schema_privileges' => 'ALL PRIVILEGES',
          'table_privileges' => 'ALL PRIVILEGES',
        },
      ],
    },
  ]
end

def lambda_users
  [
    {
      'schemas' => ['idp', 'logs'],
      'user_name' => "IAMR:#{env_name}_db_consumption",
    },
  ]
end

def query_succeded?(id)
  query_end_states = ['FINISHED', 'ABORTED', 'FAILED']
  current_query_state = {}

  until query_end_states.include?(current_query_state['status'])
    sleep 1
    current_query_state = redshift_data_client.describe_statement(id:)
  end

  return true if current_query_state['status'] == 'FINISHED'

  raise "Redshift Data API query failed: #{current_query_state['error']} | #{current_query_state['query_string']}"
end

def query_results(id)
  redshift_data_client.get_statement_result(
    id:
  ).to_h[:records].flatten.map { |record| record[:string_value] }
end

# Can't rely on the API's parameters (they don't allow the username to be parameterized),
# check for allowed characters instead
def disallowed_characters?(username)
  username.match?(/[^A-Za-z.\-:]/)
end

def current_users
  excluded_users = ['superuser', 'rdsdb', *lambda_users.map { |lambda_user| lambda_user['user_name'] }]

  # get the list of users
  current_user_query = execute_query("SELECT usename from pg_user WHERE usename NOT IN #{quote(excluded_users)}")

  return unless query_succeded?(current_user_query['id'])

  query_results(current_user_query['id'])
end

def users_to_create(yaml, redshift)
  yaml - redshift
end

def users_to_drop(yaml, redshift)
  redshift - yaml
end

def execute_query(sql)
  redshift_data_client.execute_statement(
    cluster_identifier: "#{env_name}-analytics",
    database: 'analytics',
    secret_arn:,
    sql:
  )
end

def drop_users
  @logger.info('redshift_sync: dropping removed users')
  user_sql = users_to_drop(@canonical_users, current_users).map do |name|
    next if disallowed_characters?(name)

    @logger.info("redshift_sync: removing user #{name}")
    <<~SQL
      ALTER GROUP lg_users DROP USER "#{name}";
      DROP USER "#{name}";
    SQL
  end
  return if user_sql.empty?

  query_succeded?(execute_query(user_sql.join("\n"))['id'])
end

def create_lambda_user(user_name, schemas)
  @logger.info("redshift_sync: creating lambda user #{user_name}")

  user_exists_statement = "SELECT usename FROM pg_user WHERE usename = '#{user_name}'"
  user_exists_query = execute_query(user_exists_statement)

  if query_succeded?(user_exists_query['id'])
    user_exists_result = query_results(user_exists_query['id'])
  end

  schema_privileges = schemas.map do |schema|
    create_lambda_user_privileges(user_name, schema)
  end

  sql = [
    *("CREATE USER #{user_name} WITH PASSWORD DISABLE;" unless user_exists_result.any?),
    schema_privileges
  ]

  query_succeded?(execute_query(sql.flatten.join("\n"))['id'])
end

def create_lambda_user_privileges(user_name, schema)
  <<~SQL
    CREATE SCHEMA IF NOT EXISTS #{schema};
    GRANT CREATE ON SCHEMA #{schema} TO "#{user_name}";
    GRANT USAGE ON SCHEMA #{schema} TO "#{user_name}";
    GRANT ALL PRIVILEGES ON SCHEMA #{schema} TO "#{user_name}";
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA #{schema} TO "#{user_name}";
  SQL
end

def create_user_group(user_group)
  @logger.info("redshift_sync: creating user group #{user_group['name']}")
  groups_exist_query = execute_query("SELECT groname FROM pg_group WHERE groname = #{quote(user_group['name'])}")

  if query_succeded?(groups_exist_query['id']) && query_results(groups_exist_query['id']).any?
    return
  end

  schema_privileges = user_group['schemas'].map do |schema|
    create_user_group_privileges(user_group['name'], schema['schema_name'], schema['schema_privileges'],
                                 schema['table_privileges'])
  end

  sql = <<~SQL
      CREATE group #{user_group['name']};
      #{schema_privileges.join("\n")}
  SQL

  query_succeded?(execute_query(sql)['id'])
end

def create_user_group_privileges(group_name, schema_name, schema_privileges, table_privileges)
  <<~SQL
    GRANT #{schema_privileges} ON SCHEMA #{schema_name} TO GROUP #{group_name};
    GRANT #{table_privileges} ON ALL TABLES IN SCHEMA #{schema_name} TO GROUP #{group_name};
  SQL
end

def create_users
  @logger.info('redshift_sync: creating new users')
  user_sql = users_to_create(@canonical_users, current_users).map do |name|
    next if disallowed_characters?(name)

    @logger.info("redshift_sync: creating user #{name}")
    <<~SQL
      CREATE USER "#{name}" WITH PASSWORD DISABLE IN GROUP lg_users;
    SQL
  end
  return if user_sql.empty?

  query_succeded?(execute_query(user_sql.join("\n"))['id'])
end

# Entry point: Syncs users by calling create_lambda_users, drop_users, and create_users
def main
  basename = File.basename($PROGRAM_NAME)

  optparse = OptionParser.new do |opts|
    opts.banner = <<~EOM
      usage: #{basename} [OPTIONS] USERS_YAML_FILE
    EOM
  end

  args = optparse.parse!

  case args.length
  when 1
    yaml_file_location = args[0]
  else
    $stderr.puts optparse
    exit 1
  end

  users_yaml = YAML.safe_load(File.open(yaml_file_location))['users'].keys
  non_human_accounts = ['project_21_bot', 'root']
  @canonical_users = (users_yaml - non_human_accounts).map { |name| "IAM:#{name}" }
  @logger = Logger.new($stdout)
  @logger.level = Logger::INFO

  lambda_users.each do |lambda_user|
    create_lambda_user(lambda_user['user_name'], lambda_user['schemas'])
  end
  user_groups.each do |user_group|
    create_user_group(user_group)
  end
  drop_users
  create_users
end

if $PROGRAM_NAME == __FILE__
  main
end

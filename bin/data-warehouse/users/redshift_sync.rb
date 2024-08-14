#!/usr/bin/env ruby
require 'yaml'
require 'aws-sdk-redshiftdataapiservice'
require 'aws-sdk-secretsmanager'
require 'logger'

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
                                             .describe_secret(secret_id: "redshift!#{env_name}-analytics-awsuser")
                                             .arn
end

def redshift_data_client
  @redshift_data_client ||= Aws::RedshiftDataAPIService::Client.new(
    credentials: instance_credentials
  )
end

def user_groups
  ['lg_users', 'lg_admins']
end

def lambda_user
  {
    'schema' => 'idp',
    'user_name' => "IAMR:#{env_name}_db_consumption",
  }
end

def query_succeded?(id)
  query_end_states = ['FINISHED', 'ABORTED', 'FAILED']
  current_query_state = {}

  until query_end_states.include?(current_query_state['status'])
    sleep 1
    current_query_state = redshift_data_client.describe_statement(id:)
  end

  return true if current_query_state['status'] == 'FINISHED'


  raise "Redshift Data API query failed: #{current_query_state['error']}"
end

# Can't rely on the API's parameters (they don't allow the username to be parameterized),
# check for allowed characters instead
def disallowed_characters?(username)
  username.match?(/[^a-z.-]/)
end

def current_users
  excluded_users = ['awsuser', 'rdsdb', "#{lambda_user['user_name']}"]

  # get the list of users
  current_user_query = execute_sql("SELECT usename from pg_user WHERE usename NOT IN #{quote(excluded_users)}")

  return unless query_succeded?(current_user_query['id'])

  redshift_data_client.get_statement_result(
    id: current_user_query['id']
  ).to_h[:records].flatten.map { |record| record[:string_value] }
end

def users_to_create(yaml, redshift)
  yaml - redshift
end

def users_to_drop(yaml, redshift)
  redshift - yaml
end

def execute_sql(sql)
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

    <<~SQL
        ALTER GROUP lg_users DROP USER "#{name}";
        DROP USER "#{name}";
    SQL
  end
  return unless user_sql.length > 0

  execute_sql(user_sql.join("\n"))
end

def create_consumption_users
  @logger.info('redshift_sync: creating lambda consumption users')

  user_exists_statement = "SELECT usename FROM pg_user WHERE usename = '#{lambda_user['user_name']}'"
  user_exists_query = execute_sql(user_exists_statement)

  if query_succeded?(user_exists_query['id'])
    user_exists_result = redshift_data_client.get_statement_result(
      id: user_exists_query['id']
    ).to_h[:records].flatten.map { |record| record[:string_value] }
  end

  return if user_exists_result.any?

  params = {
    user_name: lambda_user['user_name'],
    schema: lambda_user['schema'],
  }

  # SQL statements for db consumption user
  sql = format(<<~SQL, params)
      CREATE USER %<user_name>s WITH PASSWORD DISABLE;
      CREATE SCHEMA IF NOT EXISTS %<schema>s;
      GRANT CREATE ON SCHEMA %<schema>s TO %<user_name>s;
      GRANT USAGE ON SCHEMA %<schema>s TO %<user_name>s;
      GRANT ALL PRIVILEGES ON SCHEMA %<schema>s TO %<user_name>s;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %<schema>s TO %<user_name>s;
  SQL

  execute_sql(sql)
end

def create_user_groups
  @logger.info('redshift_sync: creating user groups')
  groups_exist_query = execute_sql("SELECT groname FROM pg_group WHERE groname IN #{quote(user_groups)}")

  if query_succeded?(groups_exist_query['id'])
    groups_exist_results = redshift_data_client.get_statement_result(
      id: groups_exist_query['id']
    ).to_h[:records].flatten.map { |record| record[:string_value] }
  end

  groups_to_create = user_groups - groups_exist_results
  return unless groups_to_create.length > 0

  sql = groups_to_create.map do |name|
    <<~SQL
        CREATE group #{name};
    SQL
  end
  execute_sql(sql.join("\n"))
end

def create_users
  @logger.info('redshift_sync: creating new users')
  user_sql = users_to_create(@canonical_users, current_users).map do |name|
    next if disallowed_characters?(name)

    <<~SQL
        CREATE USER "#{name}" WITH PASSWORD DISABLE IN GROUP lg_users;
    SQL
  end
  return unless user_sql.length > 0

  execute_sql(user_sql.join("\n"))
end

# Entry point: Syncs users by calling create_consumption_users, drop_users, and create_users
def main
  users_yaml = YAML.safe_load(File.open("#{__dir__}/../../../terraform/master/global/users.yaml"))['users'].keys
  non_human_accounts = ['project_21_bot', 'root']
  @canonical_users = users_yaml - non_human_accounts
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  create_user_groups
  create_consumption_users
  drop_users
  create_users
end

if $PROGRAM_NAME == __FILE__
  main
end

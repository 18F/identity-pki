# This resource writes deploy.json for a given application, containing useful
# information about the git revision and server.
require 'time'
require 'net/http'

property :path, String, name_property: true

property :owner, String, default: node['login_dot_gov']['system_user']
property :group, String, default: node['login_dot_gov']['system_user']

property :branch, [String, NilClass], default: nil

property :devops_dir, String, default: '/etc/login.gov/repos/identity-devops'

action :create do
  c = Chef::HTTP.new('http://169.254.169.254')
  v2_token = c.put("/latest/api/token", nil, { 'X-aws-ec2-metadata-token-ttl-seconds': "60" })
  instance_id = c.get('http://169.254.169.254/latest/meta-data/instance-id', { 'X-aws-ec2-metadata-token' => v2_token })

  deploy_dir = ::File.dirname(new_resource.path)

  file new_resource.path do
    owner new_resource.owner
    group new_resource.group

    # lazy means content gets evaluated at execution phase, which is necessary
    # in order to get the git revision
    content lazy {

      data = {
        'env' => node.chef_environment,
        'branch' => new_resource.branch,
        'user' => 'chef',
        'git_sha' => `cd #{deploy_dir} && git rev-parse HEAD`.chomp,
        'git_date' => ::Time.at(
          Integer(`cd #{deploy_dir} && git show -s --format=%ct HEAD`)
        ).iso8601,
        'chef_run_timestamp' => ::Time.new.strftime('%Y%m%d%H%M%S'),
        'fqdn' => node.fetch('fqdn'),
        'instance_id' => instance_id,
      }

      # set deprecated attribute names
      data['sha'] = data.fetch('git_sha')
      data['timestamp'] = data.fetch('chef_run_timestamp')

      if ::File.exist?(new_resource.devops_dir)
        data['devops_git_sha'] = `cd #{new_resource.devops_dir} && git rev-parse HEAD`.chomp
        data['devops_git_date'] = ::Time.at(
          Integer(`cd #{new_resource.devops_dir} && git show -s --format=%ct HEAD`)
        ).iso8601
      end

      JSON.pretty_generate(data) + "\n"
    }
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end

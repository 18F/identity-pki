#
# This recipe finds the jenkins servers and adds their ssh pubkeys in
# so that they can do deploys.
#

if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  # In the ASG world, Jenkins does not need to log into instances to do
  # deployments, but ASG upgrades are not yet supported.
  #
  # To to ASG upgrades, this instance needs IAM permission to spin up and down
  # instances and integration with monitoring so it can recycle the nodes and
  # verify that the error rate hasn't increased.
  #
  # This has to be a warning, because both types of instances call this recipe.
  log 'Jenkins is currently unsupported in an ASG, not authorizing deploy key' do
    level :warn
  end
else
  jenkins_nodes = search(:node, "jenkins_deploy_pubkey:* AND chef_environment:#{node.chef_environment}", 'jenkins_deploy_pubkey')
  jenkins_nodes.each do |n|
    file '/home/ubuntu/.ssh/authorized_keys2' do
      user 'ubuntu'
      group 'ubuntu'
      mode '0600'
      content n.jenkins_deploy_pubkey
    end
  end
end


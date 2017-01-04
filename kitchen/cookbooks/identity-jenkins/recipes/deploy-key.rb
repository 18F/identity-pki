#
# This recipe finds the jenkins servers and adds their ssh pubkeys in
# so that they can do deploys.
#
jenkins_nodes = search(:node, "jenkins_deploy_pubkey:* AND chef_environment:#{node.chef_environment}", 'jenkins_deploy_pubkey')

jenkins_nodes.each do |n|
  file '/home/ubuntu/.ssh/authorized_keys2' do
    user 'ubuntu'
    group 'ubuntu'
    mode '0600'
    content n.jenkins_deploy_pubkey
  end
end



# turn off audit logging of elasticsearch activities in the elasticsearch dir
# (this totally spams the logs)
# This will require a reboot for it to take effect, BTW
#
# XXX remove this as soon as we get this into our base AMI and it is deployed everywhere!
#
#auditctl -A exit,never -F dir=/var/lib/elasticsearch/nodes -F uid=elasticsearch
#auditctl -A exit,never -F dir=/var/lib/filebeat
#
ruby_block 'removeESauditlogs' do
  block do
    fe = Chef::Util::FileEdit.new('/etc/audit/audit.rules')
    fe.insert_line_after_match(/^-f 1$/, '-a exit,never -F dir=/var/lib/elasticsearch/nodes -F uid=elasticsearch')
    fe.insert_line_after_match(/^-f 1$/, '-a exit,never -F dir=/var/lib/filebeat')
    fe.write_file
  end
  not_if { File.readlines('/etc/audit/audit.rules').grep(/dir=\/var\/lib\/elasticsearch\/nodes -F uid=elasticsearch/).any? }
end


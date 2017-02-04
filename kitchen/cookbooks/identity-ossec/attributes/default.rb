# turn off email
default['ossec']['user']['enable_email'] = false

# turn on syslog so that ELK will get it
default['ossec']['conf']['all']['syslog_output']['server'] = '127.0.0.1'
#default['ossec']['conf']['all']['syslog_output']['format'] = 'json'

# Most of the rest of this config was taken from cloud.gov:
#  https://github.com/18F/cg-ossec-boshrelease/blob/master/jobs/ossec_client/templates/ossec-client.conf.erb

# set up rootcheck stuff
default['ossec']['conf']['all']['rootcheck']['system_audit'] = [
  '/var/ossec/etc/shared/system_audit_rcl.txt',
  '/var/ossec/etc/shared/cis_debian_linux_rcl.txt',
  '/var/ossec/etc/shared/cis_rhel_linux_rcl.txt',
  '/var/ossec/etc/shared/cis_rhel5_linux_rcl.txt'
]
default['ossec']['conf']['all']['rootcheck']['rootkit_files'] = '/var/ossec/etc/shared/rootkit_files.txt'
default['ossec']['conf']['all']['rootcheck']['rootkit_trojans'] = '/var/ossec/etc/shared/rootkit_trojans.txt'

# set up rules?
default['ossec']['conf']['all']['rules']['include'] = [
  'rules_config.xml',
  'pam_rules.xml',
  'sshd_rules.xml',
  'telnetd_rules.xml',
  'syslog_rules.xml',
  'arpwatch_rules.xml',
  'symantec-av_rules.xml',
  'symantec-ws_rules.xml',
  'pix_rules.xml',
  'named_rules.xml',
  'smbd_rules.xml',
  'vsftpd_rules.xml',
  'pure-ftpd_rules.xml',
  'proftpd_rules.xml',
  'ms_ftpd_rules.xml',
  'ftpd_rules.xml',
  'hordeimp_rules.xml',
  'roundcube_rules.xml',
  'wordpress_rules.xml',
  'cimserver_rules.xml',
  'vpopmail_rules.xml',
  'vmpop3d_rules.xml',
  'courier_rules.xml',
  'web_rules.xml',
  'apache_rules.xml',
  'nginx_rules.xml',
  'php_rules.xml',
  'mysql_rules.xml',
  'postgresql_rules.xml',
  'ids_rules.xml',
  'squid_rules.xml',
  'firewall_rules.xml',
  'cisco-ios_rules.xml',
  'netscreenfw_rules.xml',
  'sonicwall_rules.xml',
  'postfix_rules.xml',
  'sendmail_rules.xml',
  'imapd_rules.xml',
  'mailscanner_rules.xml',
  'dovecot_rules.xml',
  'ms-exchange_rules.xml',
  'racoon_rules.xml',
  'vpn_concentrator_rules.xml',
  'spamd_rules.xml',
  'msauth_rules.xml',
  'mcafee_av_rules.xml',
  'trend-osce_rules.xml',
  'ms-se_rules.xml',
  'zeus_rules.xml',
  'solaris_bsm_rules.xml',
  'vmware_rules.xml',
  'ms_dhcp_rules.xml',
  'asterisk_rules.xml',
  'ossec_rules.xml',
  'attack_rules.xml',
  'local_rules.xml'
]


default['ossec']['conf']['all']['syscheck']['frequency'] = 21600
default['ossec']['conf']['all']['syscheck']['directories'] = [
  { '@check_all' => true, 'content' => '/etc,/usr/bin,/usr/sbin' },
  { '@check_all' => true, 'content' => '/bin,/sbin' }
]

default['ossec']['conf']['all']['syscheck']['ignore'] = [
  '/etc/mtab',
  '/etc/hosts.deny'
]

default['ossec']['conf']['all']['localfile'] = [
  {'log_format' => 'syslog', 'location' => '/var/log/syslog'},
  {'log_format' => 'syslog', 'location' => '/var/log/auth.log'},
]


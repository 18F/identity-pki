system_user = node.fetch('login_dot_gov').fetch('web_system_user')

systemd_unit 'idp-jobs.service' do
  action [:create, :enable, :start]

  content <<-EOM
# Dropped off by chef
# Systemd unit for idp-jobs

[Unit]
Description=IDP Jobs Runner Service (idp-jobs)

[Service]
ExecStart=/bin/bash -c 'bin/job_runs.sh start'
EnvironmentFile=/etc/environment
WorkingDirectory=/srv/idp/current
User=#{system_user}
Group=#{system_user}

Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=idp-jobs

# attempt graceful stop first
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
  EOM
end


# Run AIDE db update at the end of the chef run, after everything has been installed.
# Do it in the background, because this takes ~6m to run, and we don't want to delay
# the host from going into service.
Chef.event_handler do
  on :run_completed do
    if File.exists?('/usr/local/bin/aide')
      pid = spawn("/usr/local/bin/aide -c /etc/aide/aide.conf --update ; cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db", :out => "/var/log/aideupdate.out", :err => "/var/log/aideupdate.err")
    else
      pid = spawn("aide.wrapper --update ; cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db", :out => "/var/log/aideupdate.out", :err => "/var/log/aideupdate.err")
    end
    Process.detach(pid)
  end
end

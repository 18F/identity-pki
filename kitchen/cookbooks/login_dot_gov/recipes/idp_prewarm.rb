# After doing the full deploy, we want to ensure that passenger is up and
# running before the ELB starts trying to health check it. We've seen some
# cases where passenger takes too long to start up the process, fails two
# health checks, and the whole instance gets terminated.
prewarm_timeout = node.fetch('login_dot_gov').fetch('passenger_prewarm_timeout')
Chef.event_handler do
  on :run_completed do
    Chef::Log.info('Pre-warming passenger by sending an HTTP request')
    cmd = Mixlib::ShellOut.new('curl', '-sk', 'https://localhost/api/health', timeout: prewarm_timeout)
    cmd.run_command
    cmd.error!
    Chef::Log.info(cmd.stdout)
    if JSON.parse(cmd.stdout)["all_checks_healthy"]
      Chef::Log.info("Success; health checks passed!")
    else
      raise ShellCommandFailed
    end
  end
end

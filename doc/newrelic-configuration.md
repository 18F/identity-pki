# New Relic Configuration

This should document all the status checks we shoudl have in New Relic.
Currently this is done manually, until
https://github.com/18F/identity-private/issues/1713 or
https://github.com/18F/identity-private/issues/1925 is done.

## Health Checks

Ping `/api/health`, for example
`https://secure.login.gov/api/health`.  See
https://synthetics.newrelic.com/accounts/1376370/monitors.

Known issue, the monitor [does not check for expired
certificates](https://github.com/18F/identity-private/issues/1967).

## Alert Conditions

See https://alerts.newrelic.com/accounts/1376370/policies, click the policy,
and then click "Alert Conditions".

- Monitor failures (see Health Checks above)
- OS alerts on CPU, Disk IO, Memory, Disk Full, Load Average
- Browser alert on total page load time
- Application error percentage, response time, throughput
- Plugins TODO

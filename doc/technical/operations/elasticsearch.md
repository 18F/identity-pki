# Elastic Search

## Checking Cluster Status

You check the cluster status using the [`for-servers` admin tool](../tools.md)
and the built in elasticsearch health checks endpoints.

For example, to see the health of all nodes in the `int` environment, you can
run:

```
bin/for-servers -q -n "login-es*-int" 'curl -k https://localhost:9200/_cluster/health?pretty=true'
```

You may need to use the `-l` option to properly set your username.

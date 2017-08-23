# Elastic Search

NOTE.  These docs apply to the [chef server model](chef-server.md).  These steps
may be different if Elasticsearch is self bootstrapping and in an auto scaling
group.  See the [Getting Starting Guide](../../getting-started.md) for the
latest documentation.

Currently, bootstrap of ES is not perfect. If you are starting up a new cluster, you may need to log into the ES nodes and do this:

* On all ES nodes, log in and do a chef-client run to make sure that everybody has everybody else's certs.
* On all nodes that are not es0 (es1, es2, etc), log in and do this:

```
service elasticsearch stop
cd /var/lib/elasticsearch/
rm -rf nodes
chef-client

```

This will make sure that all the ES nodes are in sync. To test to make sure that ES is happy, this command should have output like this (2 node cluster in this example, note number_of_nodes and status):

```
root@es1:/var/lib/elasticsearch# curl -k https://es1.login.gov.internal:9200/_cluster/health?pretty=true
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 2,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 2,
  "active_shards" : 4,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
root@es1:/var/lib/elasticsearch#

```

Orchestration is tricky, and this is just a one-time thing for a new environment, so for now, we will just do this by hand.

### CloudTrail

If this is the first environment you are spinning up, you will need to turn spin up the centralized cloudtrail bucket. Here is how:

```
./deploy apply terraform-cloudtrail

```

You may need to edit the terraform-cloudtrail/main.tf file to add in additional elk roles as you add environments so that they can access the bucket too.

Also! There seems to be some sort of incompatibility between the temporary data files of different versions of the plugins. If you are getting cloudtrail log errors, you may have to do this:

```
rm -rf /var/lib/logstash/*

```

This should clean out the incompatible files. We have also seen some strange schema/index issues that you can clear out if you delete the indexes and start over. This is a sort of nuclear option, as it deletes all logs currently indexed in the system. As we get a greater operational understanding of the magic of elasticsearch/logstash, we expect this problem to become more apparent so that we can devise a real fix. Here is how to do that:

```
curl -k -X DELETE https://es.login.gov.internal:9200/logstash-*

```

You may also have to go into kibana and tell it to refresh it's index pattern if it has the old one.`https://elk.login.gov.internal:8443/app/kibana#/management/kibana/indices/logstash-*` Then click on the orange button that has the two arrows circling around to Refresh the Field List.

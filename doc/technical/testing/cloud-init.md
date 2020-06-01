# Testing Cloud-Init

The scripts we use to build our `user_data` for Test Kitchen are modeled after
the equivalent [Terraform
libarary](https://www.terraform.io/docs/providers/template/d/cloudinit_config.html).
This should allow all cloud-init scripts to be reused both by Test Kitchen and
Terraform, so that we are running the same code in both cases.

Here's an example:

```
{
  "filename" => "set-hostname.yaml",
  "template" => "../../modules/bootstrap/cloud-init.hostname.yaml.erb",
  "content_type" => "text/cloud-config",
  "vars" => {
    "hostname_prefix" => role,
    "domain" => "ci.login.gov"
  }
}
```

The `filename` is used by cloud-init when it creates the file on the server
from the multipart MIME archive.  The `template` is the path to the erb
template on the local filesystem.  The `content_type` is the MIME type of the
file.  The `vars` hash passes all the given variables into the ERB template.

To add any more files to the bootstrap process, modify the [the common test
kitchen
configuration](https://github.com/18F/identity-devops/blob/master/nodes/common/kitchen.cloud.yml).

See [Deploying Cloud Init](../deployment/cloud-init.md) for how the user data is
passed into a deployed instance.

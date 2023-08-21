# assure that we're working with an updated package list in case anything is
# yanked between the time the image is built and an instance is provisioned.

# HACK: on us-east-1 hosts, this must run first so ubuntu-advantage-tools is available
case Chef::Recipe::AwsMetadata.get_aws_region
when 'us-east-1'
  execute 'apt-get -o DPkg::Lock::Timeout=240 update'
end

# enable ESM and then re-run apt update
package 'ubuntu-advantage-tools' do
  options '-o DPkg::Lock::Timeout=240'
end

execute 'pro config set apt_news=false'
execute 'pro refresh config'

execute 'pro enable esm-apps'
execute 'apt update'
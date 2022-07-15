# assure that we're working with an updated package list in case anything is
# yanked between the time the image is built and an instance is provisioned.
execute 'apt update'
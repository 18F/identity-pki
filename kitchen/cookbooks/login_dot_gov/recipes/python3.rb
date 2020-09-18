# install python3 and pip3
package %w(python3 python3-dev python3-pip libssl-dev libffi-dev)

# make python 3 default
execute 'update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1'
execute 'update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2'

# upgrade pip
execute 'python3 -m pip install --upgrade pip'

# install newer version of awscli/botocore to avoid docevents failures
# https://github.com/boto/boto3/issues/2596
execute 'python3 -m pip install --upgrade awscli>=1.18.140'
bash 'remove world write' do
    code 'find /usr/local/lib/python2.7/dist-packages/botocore-1.5.28-py2.7.egg/ -type f -name *.json -exec chmod o-w {} + || true'
end
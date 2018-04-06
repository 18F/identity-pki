bash 'remove world write' do
    code 'find /usr/local/lib/python2.7/dist-packages/botocore-1.5.28-py2.7.egg/ -type f -name *.json -exec chmod o-w {} + || true'
end

bash 'remove world write txt' do
    code 'find /usr/local/lib/python2.7/dist-packages/botocore-1.5.28-py2.7.egg/ -type f -name *.txt -exec chmod o-w {} + || true'
end

bash 'remove world write pem' do
    code 'find /usr/local/lib/python2.7/dist-packages/botocore-1.5.28-py2.7.egg/ -type f -name *.pem -exec chmod o-w {} + || true'
end
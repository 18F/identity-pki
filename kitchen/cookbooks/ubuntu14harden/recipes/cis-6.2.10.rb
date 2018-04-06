bash 'remove world write . files in home' do
    code 'find /home -type f -name ".*" -exec chmod g-w,o-w {} +'
end
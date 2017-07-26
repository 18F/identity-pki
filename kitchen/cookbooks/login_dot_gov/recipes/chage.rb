# Ensure root and ubuntu accounts do not expire
execute '/usr/bin/chage -E -1 root' do
  not_if 'chage -l root | grep "Account expires" | grep never'
end
execute '/usr/bin/chage -m 0 -M 99999 -I -1 -E -1 -M -1 ubuntu' do
  only_if 'chage -l ubuntu | grep -E "(Password|Account) expires" | grep -v never'
end

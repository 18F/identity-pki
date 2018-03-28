script 'remove rwx home directories' do
    interpreter "bash"
    code <<-EOH
        chmod o= /home/brody || true
        chmod o= /home/ccraig || true
        chmod o= /home/curator || true
        chmod o= /home/jbramble || true
        chmod o= /home/jhooper || true
        chmod o= /home/jgrevich || true
        chmod o= /home/jpmugizi || true
        chmod o= /home/markryan || true
        chmod o= /home/steveu || true
        chmod o= /home/monfresh || true
        chmod o= /home/mzia || true
        chmod o= /home/tblack || true
    EOH
end

script 'remove rwx directories' do
    interpreter "bash"
    code <<-EOH
        chmod o= /var/lib/landscape || true
        chmod o= /var/lib/libuuid || true
        chmod o= /var/cache/pollinate || true
        chmod o= /var/run/dbus || true
        chmod o= /opt/opscode/embedded || true
        chmod o= /var/spool/postfix || true
        chmod o= /var/run/sshd || true
        chmod o= /var/lib/colord || true
        chmod o= /usr/share/elastalert/home || true
        chmod o= /usr/share/logstash || true
    EOH
end

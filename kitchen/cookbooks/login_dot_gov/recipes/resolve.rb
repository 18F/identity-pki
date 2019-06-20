case node[:platform_version]
when '16.04'
    # add login.gov.internal as a search domain
    template '/etc/resolvconf/resolv.conf.d/tail'

    # force an update of resolve.conf based on settings in /etc/resolveconf/*
    execute '/sbin/resolvconf -u'
end
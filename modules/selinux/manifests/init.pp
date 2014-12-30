class selinux {

    file {
        "/etc/selinux/config":
            owner     => root,
            group     => root,
            mode      => 644,
            ensure    => present,
            path      =>  $operatingsystem ? {
                default => "/etc/selinux/config",
            },
    }

}

class selinux::disabled inherits selinux {
    File ["/etc/selinux/config"] {
            source => "puppet:///modules/selinux/disabled",
    }
}

class selinux::permissive inherits selinux {
    File ["/etc/selinux/config"] {
            source => "puppet:///modules/selinux/permissive",
    }
}

class selinux::enforcing inherits selinux {
    File ["/etc/selinux/config"] {
            source => "puppet:///modules/selinux/enforcing",
    }
}

class authorized_keys {
}


class authorized_keys::work {
    file {
        "/home/work/.ssh/authorized_keys":
        owner     => work,
        group     => work,
        mode      => 440,
        ensure    => present,
        source => "puppet:///modules/authorized_keys/work",
    }
}

class authorized_keys::op {
    file {
        "/home/op/.ssh/authorized_keys":
        owner     => op,
        group     => op,
        mode      => 440,
        ensure    => present,
        source => "puppet:///modules/authorized_keys/op",
    }
}


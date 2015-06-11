define project::client (
    $user,
    $owner,
    $group,

    $home_path,
    $ssh_path
) {
    user { $user:
        ensure     => present,
        managehome => true
    }

    file { $home_path:
        ensure  => directory,
        require => User[$user],
        path    => $home_path,
        owner   => $owner,
        group   => $group
    }

    file { $ssh_path:
        ensure  => directory,
        require => User[$user],
        path    => $ssh_path,
        owner   => $owner,
        group   => $group
    }
}

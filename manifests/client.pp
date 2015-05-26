define project::client (
    $user,
    $owner,
    $group,

    $home_path,
    $public_path,
    $log_path,
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

    file { $public_path:
        ensure  => directory,
        require => User[$user],
        path    => $public_path,
        owner   => $owner,
        group   => $group
    }

    # file { $log_path:
    #     ensure  => directory,
    #     require => User[$user],
    #     path    => $log_path,
    #     owner   => $owner,
    #     group   => $group
    # }


    file { $ssh_path:
        ensure  => directory,
        require => User[$user],
        path    => $ssh_path,
        owner   => $owner,
        group   => $group
    }
}

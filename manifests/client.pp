define project::client (
    $user,
    $owner,
    $group,

    $home_path,

        $ssh_path,
    $ssh_known_hosts = [],
    $ssh_config      = undef,
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


    if ($ssh_config != undef) {
        file { "${user}_ssh_config":
            ensure  => present,
            require => File[$ssh_path],
            path    => "${ssh_path}/config",
            owner   => $owner,
            group   => $group,
            mode    => '0600',
            content => $ssh_config
        }
    }

    if ($ssh_known_hosts != []) {
        file { "${user}_known_hosts":
            ensure  => present,
            require => File[$ssh_path],
            path    => "${ssh_path}/known_hosts",
            owner   => $owner,
            group   => $group,
            mode    => '0600',
            content => join($ssh_known_hosts, "\n")
        }
    }
}

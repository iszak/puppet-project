define project::client (
    $user,
    $owner,
    $group,

    $home_path,

    $ssh_known_hosts = undef,
    $ssh_config      = undef,
) {
    validate_string($user)
    validate_string($owner)
    validate_string($group)

    validate_absolute_path($home_path)

    if ($ssh_known_hosts != undef) {
      validate_array($ssh_known_hosts)
    }

    if ($ssh_config != undef) {
      validate_string($ssh_config)
    }


    $ssh_path = "${home_path}/.ssh/"

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

    if ($ssh_known_hosts != undef) {
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

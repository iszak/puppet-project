define project::client (
    $user,
    $owner,
    $group,

    $home_path,

    $ssh_private_keys     = {},

    $ssh_config           = '',
    $ssh_known_hosts      = {},

    $ssh_authorized_keys  = {},
) {
    validate_string($user)
    validate_string($owner)
    validate_string($group)

    validate_absolute_path($home_path)

    validate_hash($ssh_private_keys)
    validate_hash($ssh_known_hosts)
    validate_hash($ssh_authorized_keys)

    validate_string($ssh_config)


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


    if ($ssh_config != '') {
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

    create_resources(
      'file',
      $ssh_private_keys,
      {
        owner => $owner,
        group => $group,
        mode  => 0600
      }
    )

    create_resources(
      'ssh_authorized_key',
      $ssh_authorized_keys,
      {
        user => $user
      }
    )

    create_resources(
      'sshkey',
      $ssh_known_hosts,
      {
        target => "${ssh_path}/known_hosts"
      }
    )
}

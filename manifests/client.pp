define project::client (
    $user,
    $owner,
    $group,

    $skeleton,

    $home_path,
    $ssh_path
) {
    create_resources(
        "project::skeleton::${skeleton}",
        {
            user => {
                require => [
                    User[$user],
                    File[$home_path],
                ],
                user    => $user,
                owner   => $owner,
                group   => $group,
            }
        }
    )

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

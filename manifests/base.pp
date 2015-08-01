define project::base (
    $user,
    $owner,
    $group,

    $repo_ensure = 'present',
    $repo_path,
    $repo_source,

    $web_host,
    $web_path             = '',

    $ssh_private_keys     = {},
    $ssh_private_key_path = '',

    $ssh_config           = '',
    $ssh_known_hosts      = {},

    $ssh_authorized_keys  = {},

    $skeleton             = 'default',

    $custom_fragment      = ''
) {
    include ::git
    include ::apache

    validate_re($repo_ensure, '^(present|absent)$')
    validate_absolute_path($repo_path)
    validate_string($repo_source)

    validate_string($web_path)
    validate_string($web_host)

    validate_re($skeleton, '^(default|capistrano)$')

    validate_string($custom_fragment)

    $home_path    = "/home/${user}"
    $log_path     = "${home_path}/logs"

    if (defined(Project::Client[$user]) == false) {
        project::client { $user:
            user                => $user,
            owner               => $owner,
            group               => $group,

            home_path           => $home_path,

            ssh_private_keys    => $ssh_private_keys,

            ssh_config          => $ssh_config,
            ssh_known_hosts     => $ssh_known_hosts,

            ssh_authorized_keys => $ssh_authorized_keys,
        }
    }

    create_resources(
        "project::skeleton::${skeleton}",
        {
            "${title}" => {
                require      => [
                    Project::Client[$user],
                ],
                user         => $user,
                owner        => $owner,
                group        => $group,
                project      => $title,
                project_path => $repo_path,
            }
        }
    )

    vcsrepo { $title:
        ensure   => $repo_ensure,
        provider => 'git',
        source   => $repo_source,
        path     => $repo_path,
        user     => $user,
        owner    => $owner,
        group    => $group,
        identity => $ssh_private_key_path
    }

    # TODO: Remove hack
    exec { "/bin/chown -R ${owner}:${group} ${repo_path}/":
        require => Vcsrepo[$title],
        onlyif  => "/usr/bin/find -L ${repo_path}/ -maxdepth 2 -not -user ${owner} -print -quit | grep '.'",
    }

    apache::vhost { $web_host:
        require           => [
            Vcsrepo[$title]
        ],
        port              => 80,
        docroot           => "${repo_path}/${web_path}",
        docroot_owner     => $owner,
        docroot_group     => $group,
        logroot           => $log_path,
        passenger_app_env => $environment,
        custom_fragment   => $custom_fragment,
        override          => ['All']
    }
}

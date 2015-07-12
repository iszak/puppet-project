define project::base (
    $user,
    $owner,
    $group,

    $repo_ensure = 'present',
    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $ssh_key      = undef,
    $ssh_key_path = undef,

    $ssh_known_hosts = undef,
    $ssh_config      = undef,

    $skeleton        = 'default',

    $custom_fragment = ''
) {
    include git
    include apache

    $home_path    = "/home/${user}"
    $log_path     = "${home_path}/logs"
    $project_path = "${home_path}/${repo_path}"

    if (defined(Project::Client[$user]) == false) {
        project::client { $user:
            user           => $user,
            owner          => $owner,
            group          => $group,

            home_path       => $home_path,

            ssh_config      => $ssh_config,
            ssh_known_hosts => $ssh_known_hosts,
        }
    }

    create_resources(
        "project::skeleton::${skeleton}",
        {
            "${title}" => {
                require => [
                    Project::Client[$user],
                ],
                user    => $user,
                owner   => $owner,
                group   => $group,
                project => $title,
            }
        }
    )

    if ($ssh_key != undef and $ssh_key_path != undef) {
      file { "${title}_ssh_key":
         ensure  => present,
         require => Project::Client[$user],
         before  => Vcsrepo[$title],
         path    => $ssh_key_path,
         owner   => $owner,
         group   => $group,
         mode    => '0600',
         content => $ssh_key
      }
    }

    vcsrepo { $title:
        ensure   => $repo_ensure,
        provider => 'git',
        source   => $repo_source,
        path     => $repo_path,
        user     => $user,
        owner    => $owner,
        group    => $group,
        identity => $ssh_key_path
    }

    # TODO: Remove hack
    exec { "/bin/chown -R ${owner}:${group} ${repo_path}/":
        require => Vcsrepo[$title],
        unless  => "/usr/bin/stat -c '%U' ${repo_path}/ | /bin/grep ${owner}",
    }

    apache::vhost { $web_host:
        require           => [
            Vcsrepo[$title]
        ],
        port              => 80,
        docroot           => "${repo_path}/$web_path",
        docroot_owner     => $owner,
        docroot_group     => $group,
        logroot           => $log_path,
        passenger_app_env => $environment,
        custom_fragment   => $custom_fragment,
        override          => ['All']
    }
}

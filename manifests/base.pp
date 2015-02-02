define project::base (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $ssh_key,
    $ssh_key_path = '',

    $custom_fragment = ''
) {
    include git
    include apache

    $home_path    = "/home/${user}"
    $ssh_path     = "${home_path}/.ssh"
    $public_path  = "${home_path}/public"
    $log_path     = "${home_path}/log"
    $project_path = "${home_path}/${repo_path}"

    warning("User is ${user}")

    if (defined(Project::Client[$user]) == false) {
        project::client { $user:
            user        => $user,
            owner       => $owner,
            group       => $group,

            home_path   => $home_path,
            public_path => $public_path,
            log_path    => $log_path,
            ssh_path    => $ssh_path
        }
    }

    file { "${title}_ssh_key":
        ensure  => present,
        require => File[$ssh_path],
        path    => "${ssh_path}/${title}.key",
        owner   => $owner,
        group   => $group,
        content => $ssh_key
    }

    vcsrepo { $title:
        ensure  => present,
        require => [
            Project::Client[$user],
            File[ "${title}_ssh_key"]
        ],
        provider => 'git',
        source   => $repo_source,
        path     => $repo_path,
        user     => $user,
        owner    => $owner,
        group    => $group,
        identity => "${ssh_path}/${title}.key"
    }

    apache::vhost { $web_host:
        require         => [
            Vcsrepo[$title],
            Project::Client[$user],
            File["${title}_ssh_key"]
        ],
        port            => 80,
        docroot         => "${repo_path}/$web_path",
        docroot_owner   => $owner,
        docroot_group   => $group,
        logroot         => $log_path,
        custom_fragment => $custom_fragment,
        override        => ['All']
    }
}

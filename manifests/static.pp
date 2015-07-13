define project::static (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path        = '',
    $web_host,

    $ssh_key         = undef,
    $ssh_key_path    = undef,

    $ssh_config      = undef,
    $ssh_known_hosts = undef,

    $npm_install     = false,
    $npm_path        = '',
    $npm_timeout     = 300,

    $environment     = 'production',
) {
    include ::profile::node

    validate_bool($npm_install)
    validate_string($npm_path)
    validate_integer($npm_timeout)

    $home_path    = "/home/${user}"
    $project_path = "${home_path}/${repo_path}"

    project::base { $title:
        user            => $user,
        owner           => $owner,
        group           => $group,

        repo_path       => $project_path,
        repo_source     => $repo_source,

        web_path        => $web_path,
        web_host        => $web_host,

        ssh_key         => $ssh_key,
        ssh_key_path    => $ssh_key_path,

        ssh_known_hosts => $ssh_known_hosts,
        ssh_config      => $ssh_config,
    }


    if ($npm_install == true) {
        exec { "${title}_npm_install":
            require => [
                Class[nodejs],
                Vcsrepo[$title]
            ],
            command     => "/usr/bin/npm install",
            environment => "HOME=${home_path}",
            user        => $user,
            group       => $group,
            cwd         => "${project_path}/${npm_path}",
            creates     => "${project_path}/node_modules",
            timeout     => $npm_timeout
        }
    }
}

define project::node (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $ssh_key,
    $ssh_key_path = undef,

    $ssh_config = '',
    $ssh_known_hosts = [],

    $npm_install = true,
    $npm_path    = '',
    $npm_timeout = 300,

    $environment = 'production',

    $custom_fragment = ''
) {
    include nodejs

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

        ssh_config      => $ssh_config,
        ssh_known_hosts => $ssh_known_hosts,

        custom_fragment => "
    PassengerAppEnv ${environment}\n
    ${custom_fragment}
        "
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

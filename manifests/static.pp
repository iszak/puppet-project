define project::static (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $ssh_private_key,
    $ssh_public_key,

    $npm_install = false,
    $npm_path    = '',
    $npm_timeout = 300
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

        ssh_private_key => $ssh_private_key,
        ssh_public_key  => $ssh_public_key
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

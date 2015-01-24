define project::ruby (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $ssh_private_key,
    $ssh_public_key,

    $bundle_install = true,
    $bundle_path    = '',
    $bundle_timeout = 300,

    $environment = 'production',

    $custom_fragment = ''
) {
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
        ssh_public_key  => $ssh_public_key,
        custom_fragment => "
    RackEnv ${environment}\n
    \n\n
    ${custom_fragment}"
    }

    if ($bundle_install == true) {
        ruby::bundle { $title:
            require => [
                Class[ruby::dev],
                Vcsrepo[$title]
            ],
            command => 'install',
            option  => '--path=vendor/bundle',
            cwd     => "${project_path}/${bundle_path}",
            user    => $user,
            group   => $group,
            timeout => $bundle_timeout
        }
    }
}

define project::zf2 (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $database_type = 'postgresql',
    $database_name,
    $database_username,
    $database_password,

    $ssh_private_key,
    $ssh_public_key,

    $composer_install = true,
    $composer_path    = '',
    $composer_timeout = 300,

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
        custom_fragment => $custom_fragment
    }

    if ($database_type == 'postgresql') {
        postgresql::server::db { $database_name:
            user     => $database_username,
            password => $database_password
        }
    }

    if ($composer_install == true) {
        exec { "${title}_composer_install":
            require     => [
                Vcsrepo[crowdwish_backend],
                Project::Client[$user]
            ],
            command     => "${project_path}/${composer_path}/composer.phar install",
            environment => "HOME=${home_path}",
            user        => $user,
            group       => $group,
            cwd         => "${project_path}/${composer_path}",
            creates     => "${project_path}/vendor",
            timeout     => $composer_timeout
        }
    }

    # TODO: Conditional
    # exec { "${title}_doctrine_migration":
    #     require     => [
    #         Vcsrepo[crowdwish_backend],
    #         Exec["${title}_composer_install"]
    #     ],
    #     command     => "/usr/bin/php vendor/bin/doctrine-module migrations:migrate --no-interaction",
    #     environment => "HOME=${home_path}",
    #     user        => $user,
    #     group       => $group,
    #     cwd         => "${project_path}/"
    # }
}
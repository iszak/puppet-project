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

    $ssh_key,
    $ssh_key_path = undef,

    $ssh_config = undef,
    $ssh_known_hosts = [],

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

        ssh_key         => $ssh_key,
        ssh_key_path    => $ssh_key_path,

        ssh_config => $ssh_config,
        ssh_known_hosts => $ssh_known_hosts,

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

    exec { "${title}_config":
        require => [
            Vcsrepo[crowdwish_backend],
        ],
        command     => "/usr/bin/find web/config/ -type f -iname \"*.dist\" -execdir sh -c \"echo {} | sed 's/.dist//g' | xargs -I f cp f.dist f\" \\;",
        environment => "HOME=${home_path}",
        user        => $user,
        group       => $group,
        cwd         => "${project_path}/"
    }


    exec { "${title}_data":
        require => [
            Vcsrepo[crowdwish_backend],
        ],
        command => "/bin/chmod -R 0777 data/",
        cwd     => "${project_path}/web/"
    }


    # TODO: Conditional
    exec { "${title}_doctrine_migration":
        require     => [
            Vcsrepo[crowdwish_backend],
            Exec["${title}_composer_install"],
            Exec["${title}_data"],
            Exec["${title}_config"]
        ],
        command     => "/usr/bin/php web/vendor/bin/doctrine-module migrations:migrate --no-interaction",
        environment => "HOME=${home_path}",
        user        => $user,
        group       => $group,
        cwd         => "${project_path}/"
    }
}

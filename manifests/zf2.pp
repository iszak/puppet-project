define project::zf2 (
    $user,
    $owner,
    $group,

    $repo_path,
    $repo_source,

    $web_path = '',
    $web_host,

    $database_type,
    $database_name,
    $database_username,
    $database_password,

    $ssh_key         = undef,
    $ssh_key_path    = undef,

    $ssh_config      = undef,
    $ssh_known_hosts = undef,

    $composer_install = true,
    $composer_path    = '',
    $composer_timeout = 300,

    $migrate          = true,

    $environment      = 'production',

    $custom_fragment  = ''
) {
    include ::profile::php

    $home_path    = "/home/${user}"
    $project_path = "${home_path}/${repo_path}"

    validate_bool($composer_install)
    validate_string($composer_path)
    validate_integer($composer_timeout)

    validate_re($database_type, '^(postgresql|mysql)$')
    validate_string($database_name)
    validate_string($database_username)
    validate_string($database_password)

    validate_bool($migrate)

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
            timeout     => $composer_timeout,
            onlyif      => "/usr/bin/test $(find ${project_path}/${composer_path}/composer.lock -mtime -7 -print)"
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
        cwd         => "${project_path}/",
        onlyif      => "/usr/bin/test $(find ${project_path}/web/config/autoload/ -mtime -7 -print)"
    }

    exec { "${title}_data":
        require => [
            Vcsrepo[crowdwish_backend],
        ],
        command => "/bin/chmod -R 0777 data/",
        cwd     => "${project_path}/web/",
        onlyif  => "/usr/bin/test $(find ${project_path}/web/data/ -type d -not -perm 0777 -print -quit)"
    }


    if ($migrate) {
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
            cwd         => "${project_path}/",
            onlyif      => "/usr/bin/test $(find ${project_path}/web/migrations/ -mtime -7 -print)"
        }
    }
}

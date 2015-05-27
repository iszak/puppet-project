define project::rails (
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
    $ssh_key_path = '',

    $bundle_install = true,
    $bundle_path    = '',
    $bundle_timeout = 300,

    $capistrano = true,

    $environment = 'production',

    $custom_fragment = ''
) {
    $home_path    = "/home/${user}"
    $project_path = "${home_path}/${repo_path}"

    if ($capistrano == true) {
        project::ruby::capistrano { $title:
            user            => $user,
            owner           => $owner,
            group           => $group,
        }
    }

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

        custom_fragment => "
    PassengerStartTimeout 300\n
    \n\n
    RackEnv ${environment}\n
    ${custom_fragment}
        "
    }

    if ($bundle_install == true) {
        if ($environment == 'production') {
            $option = '--deployment'
        } else {
            $option = '--path=vendor/bundle'
        }

        ruby::bundle { $title:
            require => [
                Class[ruby::dev],
                Vcsrepo[$title]
            ],
            command => 'install',
            option  => $option,
            cwd     => "${project_path}/${bundle_path}",
            user    => $user,
            group   => $group,
            timeout => $bundle_timeout
        }
    }

    if ($database_type == 'postgresql') {
        postgresql::server::db { $database_name:
            user     => $database_username,
            password => $database_password
        }
    }

    if ($bundle_install == true) {
        $rake_require = [
            Vcsrepo[$title],
            Ruby::Bundle[$title],
            Postgresql::Server::Db[$database_name]
        ]
    } else {
        $rake_require = [
            Vcsrepo[$title],
            Postgresql::Server::Db[$database_name]
        ]
    }

    # TODO: Conditional migrate
    ruby::rake { $title:
        require   => $rake_require,
        task      => 'db:migrate',
        rails_env => $environment,
        bundle    => $bundle_install,
        user      => $user,
        group     => $group,
        cwd       => $project_path
    }
}

define project::skeleton::capistrano (
    $user,
    $owner,
    $group,
    $project,
) {
    $home_path    = "/home/${user}"

    $timestamp    = regsubst(generate('/bin/date', '+%s'), '\n', '')
    $current_path = "${home_path}/current"
    $release_path = "${home_path}/releases"
    $repo_path    = "${home_path}/repo"
    $shared_path  = "${home_path}/shared"

    $current_release_path = "${release_path}/${timestamp}"

    file { [
        $release_path,
        $shared_path
    ]:
        ensure  => directory,
        require => User[$user],
        owner   => $owner,
        group   => $group
    }


    # Release
    exec { "/bin/mkdir ${current_release_path}":
        require => [
            File[$release_path],
        ],
        user    => $user,
        group   => $group,
        unless  => "/usr/bin/test -L ${current_path}"
    }

    # Current path
    exec { "/bin/ln --symbolic --force ${current_release_path} ${current_path}":
        require => [
            Exec["/bin/mkdir ${current_release_path}"],
        ],
        before  => Vcsrepo[$project],
        user    => $user,
        group   => $group,
        unless  => "/usr/bin/test -L ${current_path}"
    }


    # Shared
    file { [
        "${current_release_path}/bin",
        "${current_release_path}/log",
        "${current_release_path}/tmp/pids",
        "${current_release_path}/tmp/cache",
        "${current_release_path}/tmp/sockets",
        "${current_release_path}/tmp",
        "${current_release_path}/public/system",
        "${current_release_path}/vendor",
    ]:
        ensure  => absent,
        require => [
            Vcsrepo[$title],
        ],
        force   => true,
    }


    file { [
        "${shared_path}/bin",
        "${shared_path}/log",
        "${shared_path}/tmp",
        "${shared_path}/public",
        "${shared_path}/vendor",
    ]:
        ensure => directory,
        force  => true,
        owner  => $owner,
        group  => $group,
    }


    file { [
        "${shared_path}/tmp/pids",
        "${shared_path}/tmp/cache",
        "${shared_path}/tmp/sockets",
        "${shared_path}/public/system",
        "${shared_path}/vendor/bundle",
    ]:
        ensure    => directory,
        require   => [
            File["${shared_path}/bin"],
            File["${shared_path}/log"],
            File["${shared_path}/tmp"],
            File["${shared_path}/public"],
            File["${shared_path}/vendor"],
        ],
        owner     => $owner,
        group     => $group,
     }

    exec { [
        "/bin/ln --symbolic --force ${shared_path}/bin ${current_release_path}/bin",
    ]:
        require => [
            File["${current_release_path}/bin"],
            File["${shared_path}/log"],
        ],
        user      => $user,
        group     => $group,
        unless    => "/usr/bin/test -L ${current_path}/bin",
    }



    exec { [
        "/bin/ln --symbolic --force ${shared_path}/log ${current_release_path}/log",
    ]:
        require => [
            File["${current_release_path}/log"],
            File["${shared_path}/log"],
        ],
        user      => $user,
        group     => $group,
        unless    => "/usr/bin/test -L ${current_path}/log",
    }


    exec { [
        "/bin/ln --symbolic --force ${shared_path}/tmp ${current_release_path}/tmp",
    ]:
        require => [
            File["${current_release_path}/tmp/pids"],
            File["${current_release_path}/tmp/cache"],
            File["${current_release_path}/tmp/sockets"],
            File["${current_release_path}/tmp"],
            File["${shared_path}/tmp"],
        ],
        user      => $user,
        group     => $group,
        unless    => "/usr/bin/test -L ${current_path}/tmp",
    }

    exec { [
        "/bin/ln --symbolic --force ${shared_path}/vendor ${current_release_path}/vendor",
    ]:
        require => [
            File["${current_release_path}/vendor"],
            File["${shared_path}/vendor"],
            File["${shared_path}/vendor/bundle"],
        ],
        user      => $user,
        group     => $group,
        unless    => "/usr/bin/test -L ${current_path}/vendor",
    }
}

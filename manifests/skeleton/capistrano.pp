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
    exec { [
        "/bin/ln --symbolic --force ${current_release_path} ${current_path}",
    ]:
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
        "${current_release_path}/vendor/bundle",
        "${current_release_path}/vendor",
        "${current_release_path}/public/system",
    ]:
        ensure  => absent,
        require => Vcsrepo[$title],
        force   => true,
    }


    file { [
        "${shared_path}/bin",
        "${shared_path}/log",
        "${shared_path}/tmp",
        "${shared_path}/vendor",
        "${shared_path}/public",
    ]:
        ensure => directory,
    }
 

     file { [
        "${shared_path}/tmp/pids",
        "${shared_path}/tmp/cache",
        "${shared_path}/tmp/sockets",
        "${shared_path}/vendor/bundle",
        "${shared_path}/public/system",
    ]:
        ensure    => directory,
        require   => [
            File["${shared_path}/bin"],
            File["${shared_path}/log"],
            File["${shared_path}/tmp"],
            File["${shared_path}/vendor"],
            File["${shared_path}/public"],
        ],
    }


    exec { [
        "/bin/ln --symbolic --force ${shared_path}/bin ${current_release_path}/bin",
        "/bin/ln --symbolic --force ${shared_path}/log ${current_release_path}/log",
        "/bin/ln --symbolic --force ${shared_path}/tmp ${current_release_path}/tmp",
        "/bin/ln --symbolic --force ${shared_path}/vendor ${current_release_path}/vendor",
    ]:
        require => [
            File["${current_release_path}/bin"],
            File["${current_release_path}/log"],
            File["${current_release_path}/tmp/pids"],
            File["${current_release_path}/tmp/cache"],
            File["${current_release_path}/tmp/sockets"],
            File["${current_release_path}/tmp"],
            File["${current_release_path}/vendor/bundle"],
            File["${current_release_path}/vendor"],
            File["${current_release_path}/public/system"],
            File["${shared_path}/bin"],
            File["${shared_path}/log"],
            File["${shared_path}/tmp"],
            File["${shared_path}/vendor"],
        ],
        user      => $user,
        group     => $group,
    }
}

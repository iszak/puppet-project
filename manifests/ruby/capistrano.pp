define project::ruby::capistrano (
    $user,
    $owner,
    $group,
) {
    $home_path    = "/home/${user}"

    $timestamp    = generate('/bin/date', '+%s')
    $current_path = "${home_path}/current"
    $release_path = "${home_path}/releases"
    $repo_path    = "${home_path}/repo"
    $shared_path  = "${home_path}/shared"

    $current_release_path = "${release_path}/${timestamp}"

    file { [
        $release_path,
        $repo_path,
        $shared_path,
    ]:
        ensure  => directory,
        require => User[$user],
        owner   => $owner,
        group   => $group
    }

    exec { "/bin/mkdir ${current_release_path}":
        require => File[$release_path],
        user    => $user,
        group   => $group,
        unless  => "/usr/bin/test -L ${current_path}"
    }

    exec { "/bin/ln -s ${current_release_path} ${current_path}":
        require => [
            Exec["/bin/mkdir ${current_release_path}"],
        ],
        user    => $user,
        group   => $group,
        unless  => "/usr/bin/test -L ${current_path}"
    }
}

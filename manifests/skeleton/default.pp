define project::skeleton::default (
    $owner,
    $group,
    $user,
    $project,
) {
    $home_path    = "/home/${user}"
    $public_path  = "${home_path}/public"

    file { $public_path:
        ensure  => directory,
        require => User[$user],
        path    => $public_path,
        owner   => $owner,
        group   => $group
    }
}

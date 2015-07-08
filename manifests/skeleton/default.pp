define project::skeleton::default (
    $owner,
    $group,
    $user,
    $project,
) {
    $home_path    = "/home/${user}"
    $public_path  = "${home_path}/public"
}

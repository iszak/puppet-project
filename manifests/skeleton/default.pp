define project::skeleton::default (
    $owner,
    $group,
    $user,
    $project,
) {
    validate_string($user)
    validate_string($owner)
    validate_string($group)
    validate_string($project)

    $home_path    = "/home/${user}"
    $public_path  = "${home_path}/public"
}

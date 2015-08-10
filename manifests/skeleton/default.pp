define project::skeleton::default (
  $owner,
  $group,
  $user,
  $project,
  $project_path,
) {
  validate_string($user)
  validate_string($owner)
  validate_string($group)
  validate_string($project)
}

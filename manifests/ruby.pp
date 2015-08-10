define project::ruby (
  $user,
  $owner,
  $group,

  $repo_path,
  $repo_source,
  $repo_revision,

  $web_host,
  $web_path             = '',

  $ssh_private_keys     = {},
  $ssh_private_key_path = '',

  $ssh_config           = '',
  $ssh_known_hosts      = {},

  $ssh_authorized_keys  = {},

  $bundle_install       = true,
  $bundle_path          = '',
  $bundle_timeout       = 300,

  $environment          = 'production',

  $custom_fragment      = ''
) {
  include ::profile::ruby

  validate_bool($bundle_install)
  validate_string($bundle_path)
  validate_integer($bundle_timeout)

  $home_path    = "/home/${user}"
  $project_path = "${home_path}/${repo_path}"

  project::base { $title:
    user                 => $user,
    owner                => $owner,
    group                => $group,

    repo_path            => $project_path,
    repo_source          => $repo_source,
    repo_revision        => $repo_revision,

    web_path             => $web_path,
    web_host             => $web_host,

    ssh_private_keys     => $ssh_private_keys,
    ssh_private_key_path => $ssh_private_key_path,

    ssh_config           => $ssh_config,
    ssh_known_hosts      => $ssh_known_hosts,

    ssh_authorized_keys  => $ssh_authorized_keys,

    custom_fragment      => $custom_fragment
  }

  if ($bundle_install == true) {
    ruby::bundle { $title:
      require => [
        Class[ruby::dev],
        Vcsrepo[$title]
      ],
      command => 'install',
      option  => '--path=vendor/bundle',
      cwd     => "${project_path}/${bundle_path}",
      user    => $user,
      group   => $group,
      timeout => $bundle_timeout,
      onlyif  => "/usr/bin/test $(find ${project_path}/${bundle_path}/Gemfile.lock -mtime -7 -print)"
    }
  }
}

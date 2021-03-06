define project::static (
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

  $npm_install          = false,
  $npm_path             = '',
  $npm_timeout          = 300,

  $environment          = 'production',
) {
  include ::profile::node

  validate_bool($npm_install)
  validate_string($npm_path)
  validate_integer($npm_timeout)

  $home_path    = "/home/${user}"
  $project_path = "${home_path}/${repo_path}"

  project::base { $title:
    user                 => $user,
    owner                => $owner,
    group                => $group,

    repo_ensure          => 'present',
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
  }


  if ($npm_install == true) {
    exec { "${title}_npm_install":
      require     => [
        Class[nodejs],
        Vcsrepo[$title]
      ],
      command     => '/usr/bin/npm install',
      environment => "HOME=${home_path}",
      user        => $user,
      group       => $group,
      cwd         => "${project_path}/${npm_path}",
      creates     => "${project_path}/node_modules",
      timeout     => $npm_timeout
    }
  }
}

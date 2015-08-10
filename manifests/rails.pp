define project::rails (
  $user,
  $owner,
  $group,

  $repo_path,
  $repo_source,
  $repo_revision,

  $database_type,
  $database_name,
  $database_username,
  $database_password,

  $web_host,
  $web_path             = '',

  $ssh_private_keys     = {},
  $ssh_private_key_path = '',

  $ssh_config           = '',
  $ssh_known_hosts      = {},

  $ssh_authorized_keys  = {},

  $bundle_install       = true,
  $bundle_path          = '',
  $bundle_timeout       = 600,

  $migrate              = true,
  $capistrano           = false,

  $environment          = 'production',

  $custom_fragment      = '',

  $secrets              = {}
) {
  include ::profile::ruby

  validate_bool($bundle_install)
  validate_string($bundle_path)
  validate_integer($bundle_timeout)

  validate_re($database_type, '^(postgresql|mysql)$')
  validate_string($database_name)
  validate_string($database_username)
  validate_string($database_password)

  validate_bool($migrate)
  validate_bool($capistrano)

  $home_path    = "/home/${user}"

  if ($capistrano == true) {
    $skeleton     = 'capistrano'
    $project_path = "${home_path}/${repo_path}/current"
  } else {
    $skeleton     = 'default'
    $project_path = regsubst("${home_path}/${repo_path}", '/$', '')
  }

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

    skeleton             => $skeleton,

    custom_fragment      => $custom_fragment
  }

  if ($secrets != {}) {
    file { "${title}_secrets":
      ensure  => present,
      path    => "${project_path}/config/secrets.yml",
      require => Project::Base[$title],
      owner   => $owner,
      group   => $group,
      content => template('project/rails/secrets.yml.erb'),
    }
  }

  if ($bundle_install == true) {
    $rake_require = [
      Vcsrepo[$title],
      Ruby::Bundle[$title],
      Postgresql::Server::Db[$database_name],
    ]

    if ($database_type == 'postgresql') {
      $bundle_require = [
        Class[ruby::dev],
        Project::Base[$title],
        Class[postgresql::lib::devel],
        Package['postgresql-server-dev-9.3'],
      ]
    } else {
      $bundle_require = [
        Class[ruby::dev],
        Project::Base[$title],
      ]
    }
  } else {
    $rake_require = [
      Vcsrepo[$title],
      Postgresql::Server::Db[$database_name],
    ]
  }

  if ($bundle_install == true) {
    if ($environment == 'production') {
      $option = '--deployment'
    } else {
      $option = '--path=vendor/bundle'
    }

    ruby::bundle { $title:
      require => $bundle_require,
      command => 'install',
      option  => $option,
      cwd     => "${project_path}/${bundle_path}",
      user    => $user,
      group   => $group,
      timeout => $bundle_timeout,
      unless  => "/usr/bin/test $(find ${project_path}/${bundle_path}/Gemfile.lock -mtime -1 -print)"
    }
  }

  if ($database_type == 'postgresql') {
    postgresql::server::db { $database_name:
      user     => $database_username,
      password => $database_password
    }
  }

  if ($migrate == true) {
    ruby::rake { $title:
      require   => $rake_require,
      task      => 'db:migrate',
      rails_env => $environment,
      bundle    => $bundle_install,
      user      => $user,
      group     => $group,
      cwd       => $project_path,
      onlyif    => "/usr/bin/test $(find ${project_path}/db/migrate -mtime -7 -print -quit)"
    }
  }
}

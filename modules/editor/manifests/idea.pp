class editor::idea($idea_edition) {
  include vagrant::user

  $idea_name = "idea$idea_edition"
  $idea_version = '12.0.4'
  $idea_build = '123.169'
  $idea_tarball_name = "${idea_name}-${idea_version}.tar.gz"
  $idea_config_dir = $idea_edition ? {
    'IC' => '/home/vagrant/.IdeaIC12',
    'IU' => '/home/vagrant/.IntelliJIdea12',
  }

  wget::fetch { "$idea_name":
    source => "http://download.jetbrains.com/idea/$idea_tarball_name",
    destination => "/vagrant-share/apps/$idea_tarball_name",
  }

  exec { "extract-$idea_name":
    command => "/bin/tar -zxf /vagrant-share/apps/$idea_tarball_name --directory=/opt",
    creates => "/opt/idea-${idea_edition}-${idea_build}/bin",
    require => Wget::Fetch["$idea_name"],
  }

  file { "/opt/$idea_name":
    ensure => link,
    target => "/opt/idea-${idea_edition}-${idea_build}",
    require => Exec["extract-$idea_name"],
  }

  file { "/opt/$idea_name/bin/idea48.png":
    ensure => present,
    mode => 664,
    owner => 'vagrant',
    group => 'vagrant',
    source => "/vagrant-share/conf/idea48.png",
    require => [File["/opt/$idea_name"], User['vagrant'], Group['vagrant']],
  }

  file { "/home/vagrant/Desktop/$idea_name.desktop":
    ensure => present,
    mode => 775,
    owner => 'vagrant',
    group => 'vagrant',
    source => "/vagrant-share/conf/$idea_name.desktop",
    require => File["/opt/$idea_name/bin/idea48.png"],
  }

  # Set limit of watched file handles (inotify)
  # http://confluence.jetbrains.net/display/IDEADEV/Inotify+Watches+Limit
  line::present { 'inotify-watch-limit':
    file => '/etc/sysctl.conf',
    line => 'fs.inotify.max_user_watches = 524288',
  }

  exec { 'apply-inotify-watch-limit':
    command => '/sbin/sysctl -p',
    unless => '/sbin/sysctl fs.inotify.max_user_watches | /bin/grep 524288',
    require => Line::Present['inotify-watch-limit'],
  }

  file { "$idea_config_dir":
    ensure => directory,
    mode => 775,
    owner => 'vagrant',
    group => 'vagrant',
    require => [User['vagrant'], Group['vagrant']],
  }

  file { "$idea_config_dir/config":
    ensure => directory,
    mode => 775,
    owner => 'vagrant',
    group => 'vagrant',
    require => File["$idea_config_dir"],
  }

  file { "$idea_config_dir/config/plugins":
    ensure => directory,
    mode => 775,
    owner => 'vagrant',
    group => 'vagrant',
    require => File["$idea_config_dir/config"],
  }

  # Disable IntelliJ IDEA plugins not needed
  file { "$idea_config_dir/config/disabled_plugins.txt":
    ensure => present,
    mode => 664,
    owner => 'vagrant',
    group => 'vagrant',
    source => '/vagrant-share/conf/disabled_plugins.txt',
    require => File["$idea_config_dir/config"],
  }

  case $operatingsystem {
    'Ubuntu': {
      include ubuntu::keybindings

      package { 'gtk2-engines-pixbuf':
        ensure => present,
      }
    }
  }
}


class base_class {
  # Puppet 的主计划任务, 执行此计划任务即用来同步配置.
  cron { "puppet":
    ensure => present,
    command => "ps aux | grep \"puppet agent\" | grep -v grep|awk '{print \$2}'|xargs -n 1 kill -9 &>/dev/null ;sleep 5;/bin/rm -f /var/lib/puppet/state/agent_catalog_run.lock ;/usr/bin/puppet agent --onetime --no-daemonize --server=puppetlb.corp.wandoujia.com --ca_server=puppetca.corp.wandoujia.com --syslogfacility=local6 &>/dev/null",
    user => 'root',
    minute => [ fqdn_rand(30), 30+fqdn_rand(30) ]
  }

  class { 'selinux::disabled':
  }

  package { "bash":
    ensure => latest,
  }

  package { "python-requests":
    ensure => latest,
  }

  package { "python-pip":
    ensure => latest,
  }

  package {"rsyslog":
    ensure => latest,
  }
  service {"rsyslog":
    ensure => true,
    enable => true,
    hasrestart => false,
  }
  file {"/etc/rsyslog.conf":
    source =>"puppet:///modules/rsyslog.conf/rsyslog.conf",
    group => root,
    owner => root,
    mode  => 644,
  }

  # 主要加了一个 set background=dark.
  file {"/etc/vimrc":
    source =>"puppet:///modules/vimrc/vimrc",
    group => root,
    owner => root,
    mode  => 644,
  }

  # 修改 sar 的执行频率.
  file {"/etc/cron.d/sysstat":
    source =>"puppet:///modules/sysstat/sysstat",
    group => root,
    owner => root,
    mode  => 644,
  }

  # 主要是修改 DAEMON_COREFILE_LIMIT="unlimited", 和 core 相关.
  file {"/etc/sysconfig/init":
    source =>"puppet:///modules/sysconfig_init/init",
    group => root,
    owner => root,
    mode  => 644,
  }

  # 自定义的 yum 仓库.
  package { "wandoulabs-release":
    ensure => latest,
  }

  # supervisor 用来保证系统工具正常运行.
  package {"supervisor":
    ensure => latest,
  }
  service {"supervisord":
    ensure => true,
    enable => true,
    hasrestart => true,
  }
  file {"/etc/supervisord.conf":
    source =>"puppet:///modules/supervisord_conf/supervisord.conf",
    group => root,
    owner => root,
    mode  => 644,
  }

  # 所有机器安装 lighttpd 用于 nginx 7 层检测.
  package {"lighttpd":
    ensure => latest,
    #ensure => absent,
  }
  service {"lighttpd":
    ensure => true,
    enable => true,
    hasrestart => false,
  }

  # 根据机器 IP 或者主机名设置不同的 DNS 配置.
  if ("10.0.96" in $ipaddress_em2) {
    $dns_server="10.0.96.61"
  }
  # if $fqdn =~ /^stg\d+/ {
  #   $dns_server="10.0.96.61"
  # }
  elsif ".db01" in $fqdn {
    $dns_server="10.16.20.234"
  }
  elsif ".hlg01" in $fqdn {
    $dns_server="10.19.20.234"
  }
  else {
    $dns_server="10.0.12.234"
  }
  include puppi
  class { 'resolver':
    search => ['wandoujia.com'],
    dns_servers => [$dns_server],
  }

  # root 账号和密码设置.
  user{
    "root":
      ensure=> present,
      shell=>"/bin/bash",
      home=>"/root",
      managehome =>true,
      password=>'$1$3CjcO7bp$jzrMDzV0RAMU214UUYyRW1',
  }
  file {"/root/":
    mode => 550,
    group => root,
    owner => root,
    ensure => directory,
  }

  group { "work":
    gid    => 2000,
  }
  group { "op":
    gid    => 2001,
  }
  user{
    "work":
      ensure=> present,
      uid=>2000,
      gid =>2000,
      groups =>[wheel],
      shell=>"/bin/bash",
      home=>"/home/work",
      managehome =>true,
      password=>'$1$sCyMXcvD$jOiicUxPrZx.2s6rAqk3R/',
  }
  file {"/home/work":
    mode => 755,
    group => work,
    owner => work,
    ensure => directory,
  }
  file { "/home/work/.bash_logout":
    source => "/etc/skel/.bash_logout",
    owner => work,
    group => work
  }
  file { "/home/work/.bash_profile":
    source => "/etc/skel/.bash_profile",
    owner => work,
    group => work
  }
  file { "/home/work/.bashrc":
    source => "/etc/skel/.bashrc",
    owner => work,
    group => work
  }
  user{
    "op":
      ensure=> present,
      uid=>2001,
      gid =>2001,
      groups =>[wheel],
      shell=>"/bin/bash",
      home=>"/home/op",
      managehome =>true,
      password=>'$1$jBYVJteF$df6YALsdde8blPoDL2fIL.',
  }
  file {"/home/op":
    mode => 755,
    group => op,
    owner => op,
    ensure => directory,
  }
  file { "/home/op/.bash_logout":
    source => "/etc/skel/.bash_logout",
    owner => op,
    group => op
  }
  file { "/home/op/.bash_profile":
    source => "/etc/skel/.bash_profile",
    owner => op,
    group => op
  }
  file { "/home/op/.bashrc":
    source => "/etc/skel/.bashrc",
    owner => op,
    group => op
  }

  # 自定义脚本, 用来处理一些不好配置
  file {"/root/custom_script.sh":
	  source =>"puppet:///modules/custom_script/custom_script.sh",
	  group => root,
	  owner => root,
	  mode  => 700,
	  }
  exec {
  "custom script file":
    command =>"sh /root/custom_script.sh",
    user =>"root",
    path =>["/usr/bin","/usr/sbin","/bin","/bin/sh"],
  }

  # 用来保证信任, 这里使用脚本的目的是不固定死文件, 保证部分公钥的存在, 如果添加其他公钥
  # 不会删除.
  # 如果想固定死文件, 用 authorized_keys 这个 module.
  file {"/root/authorized_keys.sh":
    source =>"puppet:///modules/authorized_keys_script/authorized_keys.sh",
    group => root,
    owner => root,
    mode  => 700,
  }
  exec {
  "confirm .ssh/authorized_keys file":
    command =>"sh /root/authorized_keys.sh",
    user =>"root",
    path =>["/usr/bin","/usr/sbin","/bin","/bin/sh"],
  }

  # 用来保证用户有 sudo 权限.
  file {"/root/sudoers.sh":
    source =>"puppet:///modules/sudoers_script/sudoers.sh",
    group => root,
    owner => root,
    mode  => 700,
  }
  exec {
  "confirm /etc/sudoers file":
    command =>"sh /root/sudoers.sh",
    user =>"root",
    path =>["/usr/bin","/usr/sbin","/bin","/bin/sh"],
  }

}


class common_base {
  include base_class

  class { '::ntp':
    # servers => [ 'ntp.wandoulabs.com'],
    service_enable => false,
    service_ensure => stopped,
  }

  cron { "ntpdate":
    ensure => present,
    command => "/usr/sbin/ntpdate ntp.wandoulabs.com &>/dev/null ;/sbin/hwclock -w ",
    user => 'root',
    minute => [ fqdn_rand(30), 30+fqdn_rand(30) ]
  } 
}


class ntpserver_base {
  include base_class

  class { '::ntp':
    servers => [ '0.pool.ntp.org', '1.pool.ntp.org','stdtime.gov.hk' ],
  }
}


# ntp 服务器配置.
node /^ntp.*/ {
  include ntpserver_base
}


# 默认配置.
node default {
  include common_base
}

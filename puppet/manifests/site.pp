node default {

  include apt
  include supervisord
 
  exec { 'go get github.com/adetante/hadiscover':
    #   environment => ['GOROOT=/usr/lib/go', 'GOPATH=$HOME/go', 'PATH=$PATH:$GOROOT/bin:$GOPATH/bin'],
    command         => "/usr/bin/go get github.com/adetante/hadiscover",
    creates         => "/root/go/src/github.com/adetante",
  }
  
  file { '/etc/bash.bashrc': 
    ensure => present,
    source => "puppet:///modules/golang/bashrc",
    before => Exec['go get github.com/adetante/hadiscover'],
  }

  file { '/etc/haproxy/haproxy.cfg.tpl':
    ensure => present,
    source => "puppet:///modules/hadiscover/haproxy.cfg.tpl",
    before => Exec['go get github.com/adetante/hadiscover'],
  }

  file { '/var/log/etcd/':
    ensure   => directory,
    before => Class['::etcd'],
  }
    
  #  file { '/etc/synapse.json.conf':
  #  ensure => present,
  #  before => Supervisord::Program['synapse'],
  #  source => "puppet:///modules/synapse/synapse.json.conf",
  #}

  $go_packages = ['golang', 'golang-go.tools', 'gccgo-go', 'mercurial']
  $build_packages = ['build-essential', 'python-pip', 'ruby', 'ruby-dev' ] 

  package { $go_packages:
    ensure => installed,
    before => Exec['go get github.com/adetante/hadiscover'],
  }

  package { $build_packages:
    ensure => installed,
    before => Exec['go get github.com/adetante/hadiscover'],
  }
 
  package { 'synapse':
    ensure   => installed,
    provider => gem,
  }

  package { 'haproxy':
    ensure    => installed,
    require   => Apt::Ppa['ppa:vbernat/haproxy-1.5'],
    #  before => Supervisord::Program['synapse'],
  }

  service { 'haproxy':
    ensure  => running,
    require => Package['haproxy'],
  }
  
  apt::key { "Georiot":
    key        => "0211F6D4",
    key_source => "http://puppetmaster.georiot.com:8090/binary/keyFile",
    before     => Class['::etcd'], 
  }

  apt::source { 'georiot':
    location     => 'http://puppetmaster.georiot.com:8090/binary',
    include_src  => false,
    release      => "",
    repos        => '/',
    before       => Class['::etcd'], 
  }

  apt::ppa { 'ppa:vbernat/haproxy-1.5': }

 
  class { '::etcd':
    #discovery               => true,
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    # if you are following my cluster guide, then use the token you created for you cluster here
    #discovery_token        => "",
    name                    => $hostname,
    peer_election_timeout   => 500,
    peer_heartbeat_interval => 100,
    addr                    => "${::ipaddress_eth0_0}:4001",
    bind_addr               => "",
    peer_addr               => "${::ipaddress_eth0_0}:7001",
    peer_bind_addr          => "${::ipaddress_eth0_0}:7001",
    snapshot                => true,
    verbose                 => false,
    very_verbose            => false,
  }
 
  # Test once etcd patch is merged into synapse
  #supervisord::program { 'synaspe':
  #  command    => 'synapse -c /etc/synapse.json.conf',
  #  priority => '100',
  #}

  supervisord::program { 'hadiscover':
    command  => '/root/go/bin/hadiscover --config /etc/haproxy/haproxy.cfg.tpl --etcd http://localhost:4001 --ha /usr/sbin/haproxy --key service',
    priority => '100',
  }

}

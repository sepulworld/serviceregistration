node default {

  include apt
  include supervisord

  file { '/etc/synapse.json.conf':
    ensure => present,
    before => Supervisord::Program['synapse'],
    source => "puppet:///modules/synapse/synapse.json.conf.registration",
  }

  $build_packages = ['build-essential', 'python-pip', 'ruby', 'ruby-dev' ] 

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

 
  supervisord::program { 'synaspe':
    command    => 'synapse -c /etc/synapse.json.conf',
    priority => '100',
  }

}

node default {

  include supervisord

  file { '/etc/synapse.json.conf':
    ensure => present,
    before => Supervisord::Program['synapse'],
    source => "puppet:///modules/synapse/synapse.json.conf",
  }

  package { 'synapse':
    ensure   => installed,
    provider => gem,
  }

  package { 'build-essentials':
    ensure => installed,
  }

  package { 'ruby':
    ensure => installed,
  }

  package { 'ruby-dev':
    ensure => installed,
  }
  
  package { 'haproxy':
    ensure => installed,
  }

  package { 'pip':
    ensure => installed,
  }

  package { 'etcd':
    ensure  => installed,
    before  => Class['::etcd'],
    require => [Apt::Key["Georiot"],Apt::Source["georiot"]],
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
    repos        => '/';
    before       => Class['::etcd'], 
  }
 
  class { '::etcd':
    #discovery               => true,
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    # if you are following my cluster guide, then use the token you created for you cluster here
    #discovery_token         => "",
    #peer_election_timeout   => 500,
    #peer_heartbeat_interval => 100,
    addr                    => "${::ipaddress_eth0_0}:4001",
    bind_addr               => "",
    #peer_addr               => "${::ipaddress_eth0}:7001",
    #peer_bind_addr          => "",
    snapshot                => true,
    verbose                 => false,
    very_verbose            => false,
  }
  
  supervisord::program { 'synaspe':
      command    => 'synapse -c /etc/synapse.json.conf',
      priority => '100',
  }

}

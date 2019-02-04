require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'cumulus', 'utils.rb'))
require 'set'
require 'puppet/parameter/boolean'
Puppet::Type.newtype(:cumulus_interface) do
  desc 'Config front panel ports, SVI, loopback,
  mgmt ports on Cumulus Linux. To configure a bond use the
  cumulus_bond module. To configure a bridge interface use
  the cumulus_bridge module.
  '
  include Cumulus::Utils

  ensurable do
    newvalue(:outofsync) do
    end
    newvalue(:insync) do
      provider.update_config
    end
    def retrieve
      result = provider.config_changed?
      result ? :outofsync : :insync
    end

    defaultto do
      :insync
    end
  end

  newparam(:name) do
    desc 'interface name'
  end

  newparam(:ipv4) do
    desc 'list of ipv4 addresses
    ip address must be in CIDR format and subnet mask included
    Example: ["10.1.1.1/30"]'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:ipv6) do
    desc 'list of ipv6 addresses
    ip address must be in CIDR format and subnet mask included
    Example: ["10:1:1::1/127"]'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:alias_name) do
    desc 'interface description'
  end

  newparam(:addr_method) do
    desc 'address assignment method'
    newvalues(:dhcp, :loopback)
  end

  newparam(:speed) do
    desc 'link speed in MB. Example "1000" means 1G'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:autoneg) do
    desc 'explicitly en/disable auto negotiation (on/off)'
  end

  newparam(:mtu) do
    desc 'link mtu. Can be 1500 to 9000 KBs'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:virtual_ip) do
    desc 'virtual IP component of Cumulus Linux VRR config'
  end

  newparam(:virtual_mac) do
    desc 'virtual MAC component of Cumulus Linux VRR config'
  end

  newparam(:vids) do
    desc 'list of vlans. Only configured on vlan aware ports'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:pvid) do
    desc 'vlan transmitted untagged across the link (native vlan)'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:location) do
    desc 'location of interface files'
    defaultto '/etc/network/interfaces.d'
  end

  newparam(:mstpctl_portnetwork,
           boolean: true,
           parent: Puppet::Parameter::Boolean) do
    desc 'configures bridge assurance. Ensure that port is in vlan
    aware mode'
  end

  newparam(:mstpctl_bpduguard,
           boolean: true,
           parent: Puppet::Parameter::Boolean) do
    desc 'configures bpdu guard. Ensure that the port is in vlan
    aware mode'
  end

  newparam(:mstpctl_portadminedge,
           boolean: false,
           parent: Puppet::Parameter::Boolean) do
    desc 'configures port adminedge.'
  end

  newparam(:clagd_enable,
           boolean: true,
           parent: Puppet::Parameter::Boolean) do
    desc 'enable CLAG on the interface. Interface must be in vlan \
    aware mode. clagd_enable, clagd_peer_ip, clagd_backup_ip,
    clagd_sys_mac must be configured together'
  end

  newparam(:clagd_priority) do
    desc 'determines which switch is the primary role. The lower priority
    switch will assume the primary role. Range can be between 0-65535.
    clagd_priority, requires clagd_enable to be defined'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:clagd_peer_ip) do
    desc 'clagd peerlink adjacent port IP. clagd_enable,
    clagd_peer_ip, clagd_sys_mac and clagd_sys_mac must be configured together'
  end

  newparam(:clagd_backup_ip) do
    desc 'Specify a backup link for your peers in the event that the peer link goes down. clagd_enable must be enabled for this config to work'
  end

  newparam(:clagd_sys_mac) do
    desc 'clagd system mac. Must the same across both Clag switches.
    range should start with 44:38:39:ff. clagd_enable, clagd_peer_ip,
    clagd_sys_mac, must be configured together'
  end

  newparam(:clagd_args) do
    desc 'additional Clag parameters. must be configured with other
    clagd parameters. It is optional'
  end

  newparam(:gateway) do
    desc 'default gateway'
  end

  validate do
    myset = [self[:clagd_enable].nil?, self[:clagd_peer_ip].nil?,
             self[:clagd_sys_mac].nil?].to_set
    if myset.length > 1
      fail Puppet::Error, 'Clagd parameters clagd_enable,
      clagd_peer_ip and clagd_sys_mac must be configured together'
    end

    unless self[:clagd_args].nil?
      if self[:clagd_enable].nil?
        fail Puppet::Error, 'Clagd must be enabled for clagd_args to be active'
      end
    end

    unless self[:clagd_priority].nil?
      if self[:clagd_enable].nil?
        fail Puppet::Error, 'Clagd must be enabled for clagd_priority
        to be active'
      end
    end

    unless self[:clagd_backup_ip].nil?
      if self[:clagd_enable].nil?
        fail Puppet::Error, 'Clagd must be enabled for clag_backup_ip to be applied'
      end
    end

    if self[:virtual_ip].nil? ^ self[:virtual_mac].nil?
      fail Puppet::Error, 'VRR parameters virtual_ip and virtual_mac must be
      configured together'
    end
  end
end

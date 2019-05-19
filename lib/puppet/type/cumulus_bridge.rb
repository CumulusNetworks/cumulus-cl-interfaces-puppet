require 'puppet/parameter/boolean'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'cumulus', 'utils.rb'))
Puppet::Type.newtype(:cumulus_bridge) do
  desc 'Config cumulus bridge interface'
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
    Example: 10.1.1.1/30'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:ipv6) do
    desc 'list of ipv6 addresses
    ip address must be in CIDR format and subnet mask included
    Example: 10:1:1::1/127'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:alias_name) do
    desc 'interface description'
  end

  newparam(:addr_method) do
    desc 'address assignment method'
    newvalues(:dhcp)
  end

  newparam(:speed) do
    desc 'link speed in MB. Example "1000" means 1G'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:mtu) do
    desc 'link mtu. Can be 1500 to 9000 KBs'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:vrf) do
    desc 'VRF name the interface should be attached to'
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

  newparam(:mcsnoop) do
    desc 'Enables IGMP MLD Snooping on a Bridge'
    newvalues(0, 1)
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:location) do
    desc 'location of interface files'
    defaultto '/etc/network/interfaces.d'
  end

  newparam(:stp,
           boolean: true,
           parent: Puppet::Parameter::Boolean) do
    desc 'enables spanning tree. default is "on" '
    defaultto true
  end

  newparam(:vlan_aware,
           boolean: true,
           parent:  Puppet::Parameter::Boolean) do
    desc 'enables vlan aware mode. Selects between the
    classic bridge driver and vlan aware bridge driver.
    Only one bridge should be covered in vlan aware mode'
  end

  newparam(:ports) do
    desc 'list of bridge members'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:mstpctl_treeprio) do
    desc 'spanning tree root priority. Must be a multiple of 4096'
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:gateway) do
    desc 'default gateway'
  end

  validate do
    fail Puppet::Error, 'ports list required' if self[:ports].nil?

    if self[:virtual_ip].nil? ^ self[:virtual_mac].nil?
      fail Puppet::Error, 'VRR parameters virtual_ip and virtual_mac must be
      configured together'
    end
  end
end

require 'puppet/parameter/boolean'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'cumulus', 'utils.rb'))
Puppet::Type.newtype(:cumulus_bond) do
  desc 'Configure bond interfaces on Cumulus Linux'
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
    newvalues(:dhcp)
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

  newparam(:clag_id) do
    desc 'Define which bond is in clag. the ID must the
    same for the corresponding bond on the adjacent switch'
  end

  newparam(:min_links) do
    desc 'minimum links in the bond'
    defaultto 1
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:mode) do
    desc 'bond mode'
    defaultto '802.3ad'
  end

  newparam(:lacp_rate) do
    desc 'lacp timeout rate'
    newvalues(0, 1)
    defaultto 1
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:lacp_bypass_allow) do
    desc 'allow bypass of lacp (unbond the interface)'
    newvalues(0, 1)
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:lacp_bypass_period) do
    desc 'period in seconds to allow bypass 0-900'
    newvalues(/^([0-8]?[0-9]?[0-9]?|900)$/)
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:lacp_bypass_all_active) do
    desc 'enable all-active mode for lacp bypass'
    newvalues(0, 1)
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:lacp_bypass_priority) do
    desc 'list of interfaces with their priority'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:use_carrier) do
    desc "Specifies whether or not miimon should use MII or ETHTOOL
      ioctls vs. netif_carrier_ok() to determine the link
        status. If not mentioned default is 1"
    newvalues(0, 1)
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:miimon) do
    desc 'mii link monitoring interval'
    defaultto 100
    munge do |value|
      @resource.munge_integer(value)
    end
  end

  newparam(:xmit_hash_policy) do
    desc 'bond mode'
    defaultto 'layer3+4'
  end

  newparam(:slaves) do
    desc 'list of bond members'
    munge do |value|
      @resource.munge_array(value)
    end
  end

  newparam(:gateway) do
    desc 'default gateway'
  end

  validate do
    if self[:slaves].nil?
      fail Puppet::Error, 'bond members/slaves must be configured'
    end

    if self[:virtual_ip].nil? ^ self[:virtual_mac].nil?
      fail Puppet::Error, 'VRR parameters virtual_ip and virtual_mac must be
      configured together'
    end

    if self[:lacp_bypass_priority] && self[:lacp_bypass_all_active]
      fail Puppet::Error, 'bypass_priority and bypass_all_active must not
      be configured together'
    end
  end
end

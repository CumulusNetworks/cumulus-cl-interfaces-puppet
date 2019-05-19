require 'spec_helper'
cl_iface = Puppet::Type.type(:cumulus_bond)

describe cl_iface do
  let :params do
    [
      :name,
      :ipv4,
      :ipv6,
      :alias_name,
      :addr_method,
      :mtu,
      :vrf,
      :virtual_ip,
      :virtual_mac,
      :vids,
      :pvid,
      :location,
      :mstpctl_portnetwork, :mstpctl_bpduguard, :mstpctl_portadminedge,
      :clag_id,
      :mode, :miimon, :min_links, :lacp_rate,
      :xmit_hash_policy,
      :use_carrier,
      :lacp_bypass_allow, :lacp_bypass_period, :lacp_bypass_priority, :lacp_bypass_all_active
    ]
  end

  let :properties do
    [:ensure]
  end

  it 'should have expected properties' do
    properties.each do |property|
      expect(cl_iface.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(cl_iface.parameters).to be_include(param)
    end
  end

  context 'defaults for' do
    before do
      @bondtype = cl_iface.new(name: 'bond0',
                               slaves: ['swp1-2'])
    end
    { 'lacp_rate' => 1,
      'min_links' => 1,
      'mode' => '802.3ad',
      'xmit_hash_policy' => 'layer3+4',
      'miimon' => 100 }.each do |k, v|
        context k do
          it { expect(@bondtype.value(k.to_sym)).to eq v }
        end
      end
  end

  context 'validation' do
    context 'vrr parameters' do
      context 'if not all vrr parameters are set' do
        it do
          expect do
            cl_iface.new(name: 'bond0',
                         slaves: 'swp1-2',
                         virtual_ip: '10.1.1.1/24')
          end.to raise_error
        end
        context 'if all vrr parameters are set' do
          it do
            expect do
              cl_iface.new(name: 'bond0',
                           slaves: 'swp1-2',
                           virtual_ip: '10.1.1.1/24',
                           virtual_mac: '00:00:5e:00:00:01')
            end.to_not raise_error
          end
        end
      end
    end
  end
end

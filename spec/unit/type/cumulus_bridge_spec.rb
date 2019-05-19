require 'spec_helper'
require 'pry'
cl_iface = Puppet::Type.type(:cumulus_bridge)

describe cl_iface do
  let :params do
    [
      :name,
      :ipv4,
      :ipv6,
      :alias_name,
      :addr_method,
      :speed,
      :mtu,
      :vrf,
      :virtual_ip,
      :virtual_mac,
      :vids,
      :pvid,
      :location,
      :mstpctl_treeprio,
      :vlan_aware,
      :mcsnoop,
      :ports
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
      @bondtype = cl_iface.new(name: 'br0',
                               ports: ['bond0-2'])
    end
    { stp: true }.each do |k, v|
      context k do
        it { expect(@bondtype.value(k)).to eq v }
      end
    end
  end

  context 'validation' do
    context 'ports parameter' do
      context 'if not set' do
        it do
          expect { cl_iface.new(name: 'br0') }.to raise_error
        end
      end
      context 'if set' do
        it do
          expect do
            cl_iface.new(name: 'br0',
                         ports: ['swp1-12'])
          end.to_not raise_error
        end
        it 'should be an array' do
          expect do
            cl_iface.new(name: 'br0',
                         ports: 'swp1-12, swp13')
          end.to raise_error
        end
      end
    end

    context 'vrr parameters' do
      context 'if not all vrr parameters are set' do
        it do
          expect do
            cl_iface.new(name: 'swp1',
                         ports: ['swp1-2'],
                         virtual_ip: '10.1.1.1/24')
          end.to raise_error
        end
        context 'if all vrr parameters are set' do
          it do
            expect do
              cl_iface.new(name: 'swp1',
                           virtual_ip: '10.1.1.1/24',
                           ports: ['swp1-2'],
                           virtual_mac: '00:00:5e:00:00:01')
            end.to_not raise_error
          end
        end
      end
    end
  end
end

require 'spec_helper'
cl_iface = Puppet::Type.type(:cumulus_interface)

describe cl_iface do
  let :params do
    [
      :name,
      :ipv4,
      :ipv6,
      :alias_name,
      :addr_method,
      :speed,
      :autoneg,
      :mtu,
      :virtual_ip,
      :virtual_mac,
      :vids,
      :pvid,
      :location,
      :mstpctl_portnetwork, :mstpctl_bpduguard, :mstpctl_portadminedge,
      :clagd_enable,
      :clagd_priority,
      :clagd_peer_ip,
      :clagd_sys_mac,
      :clagd_args,
      :clagd_backup_ip
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

  context 'validation' do
    context 'ip address' do
      before do
        @resource1 = cl_iface.new(name: 'swp1',
                                  ipv4: '10.1.1.1/24')
      end
      subject { @resource1.value(:ipv4) }
      it { is_expected.to eq ['10.1.1.1/24'] }
    end

    context 'vrr parameters' do
      context 'if not all vrr parameters are set' do
        it do
          expect do
            cl_iface.new(name: 'swp1',
                         virtual_ip: '10.1.1.1/24')
          end.to raise_error
        end
        context 'if all vrr parameters are set' do
          it do
            expect do
              cl_iface.new(name: 'swp1',
                           virtual_ip: '10.1.1.1/24',
                           virtual_mac: '00:00:5e:00:00:01')
            end.to_not raise_error
          end
        end

        context 'clag parameters' do
          context 'if not all clag parameters are set' do
            it do
              expect do
                cl_iface.new(name: 'swp1',
                             clagd_enable: 'yes')
              end.to raise_error
            end
          end
          context 'if not configured' do
            it { expect { cl_iface.new(name: 'swp1') }.to_not raise_error }
          end
          context 'if all are configured' do
            it do
              expect do
                cl_iface.new(name: 'swp1',
                             clagd_enable: true,
                             clagd_priority: 2000,
                             clagd_sys_mac: '44:38:38:ff:00:11',
                             clagd_peer_ip: '10.1.1.1')
              end.to_not raise_error
            end
          end
          context 'if clagd_backup_ip is specified' do
            context 'and clagd_enable' do
              context ' is not set' do
                it do
                  expect do
                    cl_iface.new(name: 'swp1',
                                 clagd_backup_ip: '1.1.1.1')
                  end.to raise_error
                end
              end
              context 'is set' do
                it do
                  expect do
                    cl_iface.new(name: 'swp1',
                                 clagd_enable: true,
                                 clagd_priority: 2000,
                                 clagd_sys_mac: '44:38:38:ff:00:11',
                                 clagd_peer_ip: '10.1.1.1',
                                 clagd_backup_ip: '10.1.2.1')
                  end.to_not raise_error
                end
              end
            end
          end

          context 'if clagd_args is specified' do
            context 'and clagd_enable' do
              context ' is not set' do
                it do
                  expect do
                    cl_iface.new(name: 'swp1',
                                 clagd_args: '--vm')
                  end.to raise_error
                end
              end
              context 'is set' do
                it do
                  expect do
                    cl_iface.new(name: 'swp1',
                                 clagd_enable: true,
                                 clagd_priority: 2000,
                                 clagd_sys_mac: '44:38:38:ff:00:11',
                                 clagd_peer_ip: '10.1.1.1',
                                 clagd_args: '--vm')
                  end.to_not raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end

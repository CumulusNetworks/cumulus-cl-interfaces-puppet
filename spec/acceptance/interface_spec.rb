require 'spec_helper_acceptance'

describe 'interfaces' do
  context 'valid simple interface' do
    it 'should work with no errors' do
      pp = <<-EOS
        cumulus_interface { 'lo':
          addr_method => 'loopback',
          notify      => Service['networking'],
        }

        cumulus_interface { 'eth0':
          addr_method => 'dhcp',
          notify      => Service['networking'],
        }

        # With all defaults
        cumulus_interface { 'swp1':
          notify => Service['networking'],
        }

        # Over-ride defaults
        cumulus_interface { 'swp2':
          ipv4                  => ['192.168.200.1'],
          ipv6                  => ['2001:db8:5678::'],
          #addr_method          => 'static',
          speed                 => '1000',
          autoneg               => 'on',
          mtu                   => 9000,
          # ifquery doesn't seem to like clagd related parameters on an interface?
          # clagd_enable        => true
          # clagd_priority      => 1
          # clagd_peer_ip       => '10.1.2.3'
          # clagd_sys_mac       => 'aa:bb:cc:dd:ee:ff'
          vids                  => ['1-4094'],
          pvid                  => 1,
          alias_name            => 'interface swp2',
          virtual_mac           => '11:22:33:44:55:66',
          virtual_ip            => '192.168.10.1',
          mstpctl_portnetwork   => true,
          mstpctl_bpduguard     => true,
          mstpctl_portadminedge => true,
          notify                => Service['networking'],
        }

        file { '/etc/network/interfaces':
          content => "source /etc/network/interfaces.d/*\n"
        }

        service { 'networking':
          ensure     => running,
          hasrestart => true,
          restart    => '/sbin/ifreload -a',
          enable     => true,
          hasstatus  => false,
          require    => File['/etc/network/interfaces']
        }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    intf_dir = File.join('', 'etc', 'network', 'interfaces.d')

    # The manifest should have created the .d directory
    describe file(intf_dir) do
      it { should be_directory }
    end

    # Should exist
    %w( eth0 lo ).each do |intf|
      describe file("#{intf_dir}/#{intf}") do
        it { should be_file }
      end
    end

    # Should have been configured
    describe file("#{intf_dir}/swp1") do
      it { should be_file }
      its(:content) { should match(/iface swp1/) }
    end

    describe file("#{intf_dir}/swp2") do
      it { should be_file }
      # its(:content) { should match(/iface swp2 inet static/) }
      its(:content) { should match(/iface swp2/) }
      its(:content) { should match(/address 192.168.200.1/) }
      its(:content) { should match(/address 2001:db8:5678::/) }
      its(:content) { should match(/mtu 9000/) }
      its(:content) { should match(/bridge-vids 1-4094/) }
      its(:content) { should match(/bridge-pvid 1/) }
      its(:content) { should match(/link-speed 1000/) }
      its(:content) { should match(/link-autoneg on/) }
      its(:content) { should match(/link-duplex full/) }
      its(:content) { should match(/alias interface swp2/) }
      its(:content) { should match(/mstpctl-portnetwork yes/) }
      its(:content) { should match(/mstpctl-bpduguard yes/) }
      its(:content) { should match(/mstpctl-portadminedge yes/) }
      its(:content) { should match(/address-virtual/) }
    end
  end
end

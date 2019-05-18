require 'spec_helper_acceptance'

describe 'interfaces' do
  context 'valid simple bond' do
    it 'should work with no errors' do
      pp = <<-EOS
        # Bond with defaults
        cumulus_bond { 'bond0':
          slaves => ['swp1-2', 'swp4'],
          notify => Service['networking'],
        }

        # Bond, over-ride all defaults
        cumulus_bond { 'bond1':
          slaves                 => ['swp5-6'],
          ipv4                   => ['10.0.0.1/24', '192.168.1.0/16'],
          ipv6                   => ['2001:db8:abcd::/48'],
          alias_name             => 'bond number 1',
          #addr_method           => 'static',
          min_links              => 2,
          mode                   => 'balance-alb',
          miimon                 => 99,
          xmit_hash_policy       => 'layer2',
          lacp_rate              => 1,
          mtu                    => 9000,
          # ifquery doesn't seem to like clagd related parameters on an interface?
          # clag_id              => 1,
          vids                   => ['1-4094'],
          pvid                   => 1,
          virtual_mac            => '11:22:33:44:55:FF',
          virtual_ip             => '192.168.20.1',
          mstpctl_portnetwork    => true,
          mstpctl_bpduguard      => true,
          mstpctl_portadminedge  => true,
          lacp_bypass_allow      => 1,
          lacp_bypass_period     => 30,
          lacp_bypass_all_active => 1,
          notify                 => Service['networking'],
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

      apply_manifest(pp, :catch_failures => true)
    end

    intf_dir = File.join('', 'etc', 'network', 'interfaces.d')

    # The manifest should have created the .d directory
    describe file(intf_dir) do
      it { should be_directory }
    end

    # Should have been created by the cumulus_bond resource
    describe file("#{intf_dir}/bond0") do
      it { should be_file }
      its(:content) { should match(/iface bond0/) }
      its(:content) { should match(/bond-slaves glob swp1-2 swp4/) }
    end

    describe file("#{intf_dir}/bond1") do
      it { should be_file }
      # its(:content) { should match(/iface bond1 inet static/) }
      its(:content) { should match(/iface bond1/) }
      its(:content) { should match(/bond-slaves glob swp5-6/) }
      its(:content) { should match(/mtu 9000/) }
      its(:content) { should match(/bond-miimon 99/) }
      its(:content) { should match(/bond-lacp-rate 1/) }
      its(:content) { should match(/bond-min-links 2/) }
      its(:content) { should match(/bridge-vids 1-4094/) }
      its(:content) { should match(/bridge-pvid 1/) }
      its(:content) { should match(/alias bond number 1/) }
      its(:content) { should match(/bond-mode balance-alb/) }
      its(:content) { should match(/bond-xmit-hash-policy layer2/) }
      its(:content) { should match(%r{address 10.0.0.1/24}) }
      its(:content) { should match(%r{address 192.168.1.0/16}) }
      its(:content) { should match(%r{address 2001:db8:abcd::/48}) }
      its(:content) { should match(/address-virtual 11:22:33:44:55:FF 192.168.20.1/) }
      its(:content) { should match(/mstpctl-portnetwork yes/) }
      its(:content) { should match(/mstpctl-bpduguard yes/) }
      its(:content) { should match(/mstpctl-portadminedge yes/) }
      its(:content) { should match(/bond-lacp-bypass-period 30/) }
      its(:content) { should match(/bond-lacp-bypass-all-active 1/) }
      its(:content) { should match(/bond-lacp-bypass-allow 1/) }
    end
  end
end

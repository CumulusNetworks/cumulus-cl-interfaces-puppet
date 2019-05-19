require 'spec_helper_acceptance'

describe 'bridges' do
  context 'classic bridge driver' do
    it 'should work with no errors' do
      pp = <<-EOS
        # Classic bridge driver with defaults
        cumulus_bridge { 'br0':
          ports  => ['swp9', 'swp10-11', 'swp12'],
          notify => Service['networking'],
        }

        # Classic bridge driver over-ride all defaults
        cumulus_bridge { 'br1':
          ports            => ['swp13-14'],
          ipv4             =>  ['10.0.0.1/24', '192.168.1.0/16'],
          ipv6             => ['2001:db8:abcd::/48'],
          alias_name       => 'classic bridge number 1',
          mtu              => 9000,
          stp              => false,
          mstpctl_treeprio => 4096,
          virtual_ip       => '192.168.100.1',
          virtual_mac      => '11:22:33:44:55:66',
          notify           => Service['networking'],
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

    # classic bridge driver
    describe file("#{intf_dir}/br0") do
      it { should be_file }
      its(:content) { should match(/iface br0/) }
      its(:content) { should match(/bridge-ports swp9 glob swp10-11 swp12/) }
      its(:content) { should match(/bridge-stp yes/) }
    end

    describe file("#{intf_dir}/br1") do
      it { should be_file }
      its(:content) { should match(/iface br1/) }
      its(:content) { should match(/bridge-ports glob swp13-14/) }
      its(:content) { should match(/bridge-stp no/) }
      its(:content) { should match(/mtu 9000/) }
      its(:content) { should match(/mstpctl-treeprio 4096/) }
      its(:content) { should match(%r{address 10.0.0.1/24}) }
      its(:content) { should match(%r{address 192.168.1.0/16}) }
      its(:content) { should match(%r{address 2001:db8:abcd::/48}) }
    end
  end

  context 'vlan aware bridge driver' do
    it 'should work with no errors' do
      pp = <<-EOS
        # New bridge driver with defaults
        cumulus_bridge { 'bridge2':
          ports      => ['swp15-16'],
          vlan_aware => true,
          notify     => Service['networking'],
        }

        # New bridge driver over-ride all defaults
        cumulus_bridge { 'bridge3':
          ports            => ['swp17-18'],
          vlan_aware       => true,
          vids             => ['1-4094'],
          pvid             => 1,
          allow_untagged   => no,
          ipv4             => ['10.0.100.1/24', '192.168.100.0/16'],
          ipv6             => ['2001:db8:1234::/48'],
          alias_name       => 'new bridge number 3',
          mtu              => 9000,
          stp              => false,
          mstpctl_treeprio => 4096,
          virtual_ip       => '192.168.100.2',
          virtual_mac      => 'aa:bb:cc:dd:ee:ff',
          notify           => Service['networking'],
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

    # New bridge driver
    describe file("#{intf_dir}/bridge2") do
      it { should be_file }
      its(:content) { should match(/iface bridge2/) }
      its(:content) { should match(/bridge-vlan-aware yes/) }
      its(:content) { should match(/bridge-ports glob swp15-16/) }
      its(:content) { should match(/bridge-stp yes/) }
    end

    describe file("#{intf_dir}/bridge3") do
      it { should be_file }
      its(:content) { should match(/iface bridge3/) }
      its(:content) { should match(/bridge-vlan-aware yes/) }
      its(:content) { should match(/bridge-ports glob swp17-18/) }
      its(:content) { should match(/bridge-stp no/) }
      its(:content) { should match(/mtu 9000/) }
      its(:content) { should match(/mstpctl-treeprio 4096/) }
      its(:content) { should match(/bridge-pvid 1/) }
      its(:content) { should match(/bridge-vids 1-4094/) }
      its(:content) { should match(/bridge-allow-untagged no/) }
      its(:content) { should match(%r{address 10.0.100.1/24}) }
      its(:content) { should match(%r{address 192.168.100.0/16}) }
      its(:content) { should match(%r{address 2001:db8:1234::/48}) }
    end
  end
end

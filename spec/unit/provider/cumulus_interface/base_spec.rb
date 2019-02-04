require 'spec_helper'

provider_resource = Puppet::Type.type(:cumulus_interface)
provider_class = provider_resource.provider(:cumulus)

describe provider_class do
  before do
    # block io.open action to allow ifquery calls
    allow(IO).to receive(:popen)
    # this is not a valid entry to use in a real scenario..
    # only designed for testing
    @resource = provider_resource.new(
      name: 'swp1',
      vids: ['1-10', '20'],
      speed: 1000,
      autoneg: 'on',
      ipv4: '10.1.1.1/24',
      ipv6: ['10:1:1::1/127'],
      addr_method: 'loopback',
      alias_name: 'my int description',
      virtual_ip: '10.1.1.1/24',
      virtual_mac: '00:00:5e:00:00:01',
      mstpctl_bpduguard: true,
      mstpctl_portnetwork: false,
      mtu: 9000,
      clagd_enable: true,
      clagd_sys_mac: '44:38:39:ff:20:94',
      clagd_peer_ip: '10.1.1.1',
      clagd_backup_ip: '10.1.2.1'

    )
    @provider = provider_class.new(@resource)
  end

  context 'operating system confine' do
    subject do
      provider_class.confine_collection.summary[:variable][:operatingsystem]
    end
    it { is_expected.to eq ['cumuluslinux'] }
  end

  context 'ifquery fails to output any text. This should not happen' do
    let(:config) { @provider.instance_variable_get('@config') }
    before do
      allow(Puppet).to receive(:err).and_return('')
      mock_ifquery = double
      allow(mock_ifquery).to receive(:write).and_return('')
      allow(mock_ifquery).to receive(:close_write).and_return('')
      allow(mock_ifquery).to receive(:close).and_return('')
      allow(mock_ifquery).to receive(:read).and_return('')
      allow(IO).to receive(:popen).and_yield(mock_ifquery)
      @provider.build_desired_config
    end
    it do
      expect(File).not_to receive(:open)
      expect(Puppet).to receive(:err)
      config.write_config
    end
  end

  context 'config changed' do
    before do
      @loc_resource = provider_resource.new(
        name: 'swp1',
        vids: ['1-10', '20'])
    end
    context 'has not changed witih single ip address post 2.5.4' do
      before do
        @loc_resource = provider_resource.new(
          name: 'swp1',
          ipv4: '10.1.1.1/24'
        )
        # needed to ensure that if_to_hash() exists to get @config.currenthash
        allow(File).to receive(:exist?).and_return(true)

        current_hash = "[{ \"auto\":true,\"name\": \"swp1\",
          \"config\":{\"address\":\"10.1.1.1/24\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be false }
    end

    context 'has not changed with single ip address pre 2.5.4' do
      before do
        @loc_resource = provider_resource.new(
          name: 'swp1',
          ipv4: '10.1.1.1/24'
        )
        # needed to ensure that if_to_hash() exists to get @config.currenthash
        allow(File).to receive(:exist?).and_return(true)

        current_hash = "[{ \"addr_method\": null,\"auto\":true,\"addr_family\":null,\"name\":
        \"swp1\",\"config\":{\"address\":\"10.1.1.1/24\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be false }
    end

    context 'has changed' do
      before do
        current_hash = "[{\"addr_family\":null,\"name\":
        \"swp1\",\"config\":{\"address\":\"10.1.1.1/24\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be true }
    end

    context 'has not changed post 2.5.4' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        current_hash = "[{\"auto\":true,\"name\":\"swp1\",\"config\":{
        \"bridge-vids\":\"1-10 20\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be false }
    end

    context 'config has not changed pre 2.5.4' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        current_hash = "[{\"auto\":true, \"addr_method\":null,
        \"addr_family\":null,\"name\":\"swp1\",\"config\":{
        \"bridge-vids\":\"1-10 20\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be false }
    end
  end

  context 'desired config hash' do
    let(:confighash) { @provider.instance_variable_get('@config').confighash }
    before  do
      @provider.build_desired_config
    end
    context 'bridge options' do
      subject { confighash['config']['bridge-vids'] }
      it { is_expected.to eq '1-10 20' }
    end
    context 'link speed options' do
      subject { confighash['config']['link-speed'] }
      it { is_expected.to eq '1000' }
    end
    context 'link auto negotiation' do
      subject { confighash['config']['link-autoneg'] }
      it { is_expected.to eq 'on' }
    end
    context 'link duplex options' do
      subject { confighash['config']['link-duplex'] }
      it { is_expected.to eq 'full' }
    end
    context 'address options' do
      subject { confighash['config']['address'] }
      it { is_expected.to eq ['10.1.1.1/24', '10:1:1::1/127'] }
    end
    context 'addr_method' do
      subject { confighash['addr_method'] }
      it { is_expected.to eq 'loopback' }
    end
    context 'addr_family' do
      subject { confighash['addr_family'] }
      it { is_expected.to eq 'inet' }
    end
    context 'interface description - alias' do
      subject { confighash['config']['alias'] }
      it { is_expected.to eq 'my int description' }
    end
    context 'vrr config' do
      subject { confighash['config']['address-virtual'] }
      it { is_expected.to eq '00:00:5e:00:00:01 10.1.1.1/24' }
    end
    context 'generic attr that is a true bool' do
      subject { confighash['config']['mstpctl-bpduguard'] }
      it { is_expected.to eq 'yes' }
    end
    context 'generic attr is a false bool' do
      subject { confighash['config']['mstpctl-portnetwork'] }
      it { is_expected.to eq 'no' }
    end
    context 'mtu' do
      subject { confighash['config']['mtu'] }
      it { is_expected.to eq '9000' }
    end
    context 'clagd_enable' do
      subject { confighash['config']['clagd-enable'] }
      it { is_expected.to eq 'yes' }
    end
    context 'clagd_sys_mac' do
      subject { confighash['config']['clagd-sys-mac'] }
      it { is_expected.to eq '44:38:39:ff:20:94' }
    end
    context 'clagd_peer_ip' do
      subject { confighash['config']['clagd-peer-ip'] }
      it { is_expected.to eq '10.1.1.1' }
    end
    context 'clagd_backup_ip' do
      subject { confighash['config']['clagd-backup-ip'] }
      it { is_expected.to eq '10.1.2.1' }
    end
  end
end

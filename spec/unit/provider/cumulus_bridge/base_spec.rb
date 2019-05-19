require 'spec_helper'
require 'pry'

provider_resource = Puppet::Type.type(:cumulus_bridge)
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
      ipv4: '10.1.1.1/24',
      ipv6: ['10:1:1::1/127'],
      addr_method: 'dhcp',
      alias_name: 'my int description',
      virtual_ip: '10.1.1.1/24',
      virtual_mac: '00:00:5e:00:00:01',
      mstpctl_treeprio: 4096,
      mtu: 9000,
      vrf: 'red',
      mcsnoop: 1,
      ports: ['swp1-3', 'bond0']
    )
    @provider = provider_class.new(@resource)
  end

  context 'operating system confine' do
    subject do
      provider_class.confine_collection.summary[:variable][:operatingsystem]
    end
    it { is_expected.to eq ['cumuluslinux'] }
  end

  context 'config changed' do
    before do
      @loc_resource = provider_resource.new(
        name: 'br0',
        ports: ['swp1-3'])
    end
    context 'config has changed' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        current_hash = "[{\"addr_family\":null,\"name\":\"br0\",
        \"config\":{\"bridge-ports\":\"glob swp1-4\"}}]"
        mock_ifquery = double
        allow(mock_ifquery).to receive(:read).and_return(current_hash)
        allow(IO).to receive(:popen).and_yield(mock_ifquery)
        @loc_provider = provider_class.new(@loc_resource)
      end
      subject { @loc_provider.config_changed? }
      it { is_expected.to be true }
    end

    context 'config has not changed' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        current_hash = "[{\"auto\":true, \"addr_method\":null,
        \"addr_family\":null,
        \"name\":\"br0\",\"config\":{\"bridge-ports\":\"glob swp1-3\",
        \"bridge-stp\":\"yes\"}}]"
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
    context 'bridge members' do
      subject { confighash['config']['bridge-ports'] }
      it { is_expected.to eq 'glob swp1-3 bond0' }
    end
    context 'bridge options' do
      subject { confighash['config']['bridge-vids'] }
      it { is_expected.to eq '1-10 20' }
    end
    context 'link speed options' do
      subject { confighash['config']['link-speed'] }
      it { is_expected.to eq '1000' }
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
      it { is_expected.to eq 'dhcp' }
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
    context 'mtu config' do
      subject { confighash['config']['mtu'] }
      it { is_expected.to eq '9000' }
    end
    context 'vrf config' do
      subject { confighash['config']['vrf'] }
      it { is_expected.to eq 'red' }
    end
    context 'mcsnoop' do
      subject { confighash['config']['bridge-mcsnoop'] }
      it { is_expected.to eq '1' }
    end
  end
end

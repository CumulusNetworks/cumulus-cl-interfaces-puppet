require 'spec_helper'

provider_resource = Puppet::Type.type(:cumulus_bond)
provider_class = provider_resource.provider(:cumulus)

describe provider_class do
  before do
    # block io.open action to allow ifquery calls
    allow(IO).to receive(:popen)
    # this is not a valid entry to use in a real scenario..
    # only designed for testing
    @resource = provider_resource.new(
      name: 'bond0',
      vids: ['1-10', '20'],
      ipv4: '10.1.1.1/24',
      ipv6: ['10:1:1::1/127'],
      alias_name: 'my int description',
      virtual_ip: '10.1.1.1/24',
      virtual_mac: '00:00:5e:00:00:01',
      mstpctl_bpduguard: true,
      mstpctl_portnetwork: false,
      mtu: 9000,
      vrf: 'red',
      lacp_bypass_allow: 1,
      lacp_bypass_period: 30,
      lacp_bypass_all_active: 1,
      slaves: ['bond0-3']
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
        name: 'bond0',
        slaves: 'bond0-2',
        vids: ['1-10', '20'])
    end
    context 'config has changed' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        current_hash = "[{\"addr_family\":null,\"name\":
        \"bond0\",\"config\":{\"address\":\"10.1.1.1/24\"}}]"
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
        current_hash = "[{\"addr_family\":null,\"addr_method\":null,
        \"auto\":true,\"name\":\"bond0\",
        \"config\":{\"bond-slaves\":\"glob bond0-2\",
        \"bridge-vids\":\"1-10 20\",
        \"bond-mode\":\"802.3ad\",\"bond-min-links\":\"1\",
        \"bond-miimon\":\"100\",
        \"bond-lacp-rate\":\"1\",\"bond-xmit-hash-policy\":\"layer3+4\"}}]"
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
    context 'address options' do
      subject { confighash['config']['address'] }
      it { is_expected.to eq ['10.1.1.1/24', '10:1:1::1/127'] }
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
    context 'vrf' do
      subject { confighash['config']['vrf'] }
      it { is_expected.to eq 'red' }
    end
    context 'lacp bypass active' do
      subject { confighash['config']['bond-lacp-bypass-all-active'] }
      it { is_expected.to eq '1' }
    end
    context 'lacp bypass allow' do
      subject { confighash['config']['bond-lacp-bypass-allow'] }
      it { is_expected.to eq '1' }
    end
    context 'lacp bypass period' do
      subject { confighash['config']['bond-lacp-bypass-period'] }
      it { is_expected.to eq '30' }
    end
  end
end

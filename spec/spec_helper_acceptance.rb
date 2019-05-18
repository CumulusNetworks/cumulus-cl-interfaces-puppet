require 'beaker-rspec'
require 'pry'

# Install Puppet
hosts.each do |host|
  if host.name == 'cumulus-vx-2.5.3-puppet4'
    # Install 4.x from PuppetLabs
    on host, 'wget https://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb -O puppetlabs-release-pc1-wheezy.deb && dpkg -i puppetlabs-release-pc1-wheezy.deb'
    on host, 'apt-get update && apt-get install -y puppet-agent'
  else
    # Install 3.x FOSS from CL repository
    on host, 'apt-get update && apt-get install -y puppet'
  end
end

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    puppet_module_install(:source => module_root, :module_name => 'cumulus_interfaces')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), :acceptable_exit_codes => [0, 1]
    end
  end
end

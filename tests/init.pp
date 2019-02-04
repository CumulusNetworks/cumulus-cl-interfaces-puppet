# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
#cumulus_bridge { 'br0':
#    ports => ['swp11-12, 'swp32-33, ‘bond0’],
#    alias_name => 'vlan aware bridge',
#    mtu => '9000',
#    vids => [‘1-300’],
#    vlan_aware => true,
#    mstpctl_treeprio => '4096'
#}
cumulus_bond { 'bond0':
    slaves => ['swp3-4'],
    clag_id => 1
}
cumulus_interface { 'br0.1':
   ipv4 => '10.1.1.1/24'
}
cumulus_interface { "swp33":
   speed => 1000,
   autoneg => 'off',
   alias_name => "trunk port",
   vids => ["1-10", '12'],
   pvid => 1
}
cumulus_interface{ 'loop0':
   addr_method => 'loopback'
}
cumulus_interface{ 'swp22':
   addr_method => 'dhcp'
}

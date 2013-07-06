#!/usr/bin/env ruby

# SPOOFA - for ARP-spoofing local networks

# (C) 2013 VulpiArgenti (SilverFoxx)

require 'packetfu'
require 'optparse'
require 'ostruct'

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

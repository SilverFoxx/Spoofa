# Spoofa

A Ruby replacement for Arpspoof

### Install Requirements

```gem install pcaprub
gem install packetfu```

(If errors in Kali, first try: apt-get install ruby-dev)

Tested on Kali-linux only

### Usage

#### Interactive mode

Start without any arguments:

```ruby spoofa.rb```

Runs a quick script to set the variables. Will offer sane defaults for the various options.

#### Command line mode

```ruby spoofa.rb [-hmq] [-t target(s)] [-r gateway] -i interface```

Required:

*-i interface*

Options: 

*-h* Help

*-q* Prints minimal output to the screen

*-m* Smart ARPing; attempts to monitor ARP requests from the target(s), and only reply as necessary. *May* avoid IDS/ARPwatch etc. This feature is experimental. If not set, ARP packets are sent continuously.

*-t targets(s)* One or more targets in CIDR notation (nmap style). If omitted, the entire subnet will be targeted. Without [-r], one-way spoofing is performed.

*-r gateway* With [-t] (required), performs two-way spoofing.


### Troubleshooting

Check gems are installed:

```gem list```

Run packetfu's tests:

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/test/ && ruby all_tests.rb```

Play with packetfu's excellent irb (check is executable first):

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/examples && irb -r ./packetfu-shell.rb``` 

### Licence

See LICENSE for licensing details.


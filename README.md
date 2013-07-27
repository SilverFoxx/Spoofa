# Spoofa

A Ruby replacement for Arpspoof

### Install Requirements

```gem install pcaprub```  
```gem install packetfu```

If errors in Kali, first try: ```apt-get install ruby-dev```

Tested on Kali-linux only

### Usage

#### Interactive mode

Start without any arguments:

```ruby spoofa.rb```

Runs a quick script to set the variables. Will offer sane defaults for the various options.

#### Command line mode

```ruby spoofa.rb [-hmv] [-t target(s)] [-g gateway] -i interface```

Required:

*-i interface*

Options: 

*-h* Help

*-m* Smart ARPing; NOT YET AVAILABLE attempts to monitor ARP requests from the target(s), and only reply as necessary. *May* avoid IDS/ARPwatch etc. This feature is experimental. If not set, ARP packets are sent continuously.

*-v* Run verbosely

*-t targets(s)* One or more targets separated by comma (no whitespace), and/or a hyphened range. E.g. \"-t 192.168.1.10,192.168.1.50-100\". If omitted, the entire subnet will be targeted. Without [-g], one-way spoofing is performed, i.e. packets *from* the target are intercepted."

*-g gateway* A second target, usually the gateway. With [-t] set, performs two-way spoofing, i.e intercepts packets both to *and* from the target.


### Troubleshooting

Check gems are installed:

```gem list```

Run packetfu's tests:

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/test/ && ruby all_tests.rb```

Play with packetfu's excellent irb (check is executable first):

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/examples && irb -r ./packetfu-shell.rb``` 

### Author

VulpiArgenti (SilverFoxx)

### Licence

See LICENSE for licensing details.


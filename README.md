# Spoofa

A Ruby replacement for Arpspoof

### Install Requirements

```gem install pcaprub```  
```gem install packetfu```

### Usage

#### Interactive mode

Start without any arguments: ```ruby spoofa```

Runs a quick script to set the variables. Will offer sane defaults for the various options.

#### Command line mode

```ruby spoofa [-hmpv] [-t target(s)] [-g gateway] -i interface```

Required:

*-i interface*

Options: 

*-h* Help

[*-m* Smart ARPing; NOT YET AVAILABLE. Attempts to monitor ARP requests from the target(s), and only reply as necessary. *May* avoid IDS/ARPwatch etc.]

*-p* Uses parallel/multi-threaded scanning. Very slow without it; but possibly unstable on some systems. Best run with "-v".

*-v* Run verbosely

*-t targets(s)* One or more targets separated by comma (no whitespace), and/or hyphened range(s). E.g. "-t 192.168.1.10,192.168.1.50-100". If omitted, the entire subnet will be targeted. Without [-g], one-way spoofing is performed, i.e. packets *from* the target are intercepted."

*-g gateway* A second target, usually the gateway. Performs two-way spoofing, i.e intercepts packets both to *and* from the target.

#### Examples

```ruby spoofa -t 10.0.0.2-50 -i eth0``` One-way spoofing of 10.0.0.2 to 10.0.0.50.

```ruby spoofa -t 10.0.0.5,10.0.0.10-20 -g 10.0.0.254 -i wlan1``` Two-way spoofing of 10.0.0.5 and 10-20, and the gateway (10.0.0.254).

```ruby spoofa -vp -i wlan3``` One-way spoofing of all live hosts, verbosely, with multi-threading.

```ruby spoofa``` Starts in interactive mode, and prompts for variables.

### Troubleshooting

Tested on Kali Linux only.

Check gems are installed: ```gem list```

If errors installing gems, first try: ```apt-get install ruby-dev libpcap0.8-dev```

Run packetfu's tests:

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/test/ && ruby all_tests.rb```

Play with packetfu's excellent irb (check is executable first):

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/examples && irb -r ./packetfu-shell.rb``` 

Ensure you are connected to the network before running the script.

Multi-threading is used to speed up the scanning (live host detection). The settings are conservative (runs on 2011 MBA, VMWare Fusion, 800MB RAM assigned). If the scanning hangs, try without "-p".

Best to use a USB wireless card if running in a VM, due to the unpredictable way the VM handles address assignment.

### Author

VulpiArgenti (SilverFoxx) (C) 2013

### Licence

GPL. See LICENSE for licensing details.


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

ruby spoofa.rb -i -q  -c/s -r -t

-i (interface) 

-q (quiet)

-c/s (continuous or smart)

-g (gateway)

-t (target(s))

continuous means the network is flooded with ARP packets (like classical Arpspoof)

smart attempts to monitor ARP requests from the target(s), and only reply as necessary. *May* avoid IDS/ARPwatch etc. This feature is barely beyond experimental.

### Troubleshooting

Check gems are installed:

```gem list```

Run packetfu's tests:

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/test/ && ruby all_tests.rb```

Play with packetfu's excellent irb (check is executable first):

```cd /var/lib/gems/1.9.1/gems/packetfu-1.1.8/examples && irb -r ./packetfu-shell.rb``` 

 
  
    
    
    


  
  
  

See LICENSE for licensing details.


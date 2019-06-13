#!/bin/sh
echo "
nat-anchor \"com.apple/*\" all
rdr-anchor \"com.apple/*\" all
#rdr pass en2 inet proto tcp from any to any port 4567 -> 192.168.1.13 port 4567
rdr pass lo0 inet proto tcp from any to any port 4567 -> 192.168.1.13 port 4567
" | sudo pfctl -ef -
sudo pfctl -s nat


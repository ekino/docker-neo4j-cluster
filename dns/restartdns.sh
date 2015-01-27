#!/bin/bash

echo "init" > /restartdns.log

while inotifywait -e modify,close_write,move,create,delete /etc/dnsmasq.d
do
  echo "--> RELOAD CONFIGURATION"
  supervisorctl restart dnsmasq
done | tee /restartdns.log
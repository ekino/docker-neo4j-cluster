#!/bin/bash

echo "
        _    _
    ___| | _(_)_ __   ___
   / _ \ |/ / | '_ \ / _ \ 
  |  __/   <| | | | | (_) |
   \___|_|\_\_|_| |_|\___(_)

"
#set -x

echo "==> Starting dnsmasq (with supervisord)"
echo
supervisord -n

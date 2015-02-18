#!/bin/bash

echo "
        _    _
    ___| | _(_)_ __   ___
   / _ \ |/ / | '_ \ / _ \ 
  |  __/   <| | | | | (_) |
   \___|_|\_\_|_| |_|\___(_)

"
#set -x

# Check of env variable. Complains+Help if missing
if [ -z "$SERVER_ID" ]; then
  echo >&2 "--------------------------------------------------------------------------------"
  echo >&2 "- Missing mandatory SERVER_ID ( for example : docker run -e SERVER_ID=2 .... ) -"
  echo >&2 "--------------------------------------------------------------------------------"
  exit 1
fi

# Customize config
echo "==> Setting server IP config"
CONFIG_FILE=/etc/neo4j/neo4j.properties
SERVER_IP=$(ip route get 8.8.8.8 | awk 'NR==1{print $NF}')

sed -i 's/SERVER_ID/'$SERVER_ID'/' $CONFIG_FILE
sed -i 's/SERVER_IP/'$SERVER_IP'/' $CONFIG_FILE

echo "==> Global settings"
if [ "$SERVER_ID" = "1" ]; then
  # All this node to init the cluster all alone (initial_hosts=127.0.0.1)
  sed -i '/^ha.allow_init_cluster/s/false/true/' $CONFIG_FILE
fi

OIFS=$IFS
if [ ! -z "$CLUSTER_NODES" ]; then
  IFS=','
  for i in $CLUSTER_NODES
  do
    sed -i '/^ha.initial_hosts/s/$/'${i%%_*}':5001,/' $CONFIG_FILE
  done
  sed -i '/^ha.initial_hosts/s/,$//' $CONFIG_FILE
fi
IFS=$OIFS

echo "==> Server settings"
sed -i 's/^#\(org.neo4j.server.database.mode=\)/\1/' /etc/neo4j/neo4j-server.properties

if [ "$REMOTE_HTTP" = "true" ]; then
  sed -i '/org.neo4j.server.webserver.address/s/^#//' /etc/neo4j/neo4j-server.properties
fi

if [ "$REMOTE_SHELL" = "true" ]; then
  sed -i '/remote_shell_enabled/s/^#//' $CONFIG_FILE
fi

# Review config (for docker logs)

echo "==> Settings review"
echo
(
echo " --- $(hostname) ---"
echo "Graph settings :"
grep --color -rE "allow_init_cluster|server_id|cluster_server|initial_hosts|\.server=|webserver\.address|database\.mode" /etc/neo4j/
echo
echo "Network settings :"
ip addr | awk '/inet /{print $2}'
) | awk '{print "   review> "$0}'
echo

echo "==> Starting Neo4J server (with supervisord)"
echo
supervisord -n

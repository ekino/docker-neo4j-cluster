#!/bin/bash
#set -x

command -v docker || curl http://get.docker.com/ | sh
# debugging circleci builds
docker version
ps auxf  | grep -C 10 docker
uname -a
lsb_release -a
whoami
pwd
######

cyan="$(tput setaf 6)"
green="$(tput setaf 2)"
bgreen="$(tput bold ; tput setaf 2)"
red="$(tput setaf 1)"
reset="$(tput sgr0)"

cnf='dns/dnsmasq.d'
bdd='node/data'

for args in $@
do
  case ${1%:*} in
    'build')
      echo -e "\n${cyan}==> Building DNS server image${reset}"
      docker build -t=ekino/dnsmasq:latest dns/
      echo -e "\n${cyan}==> Building neo4j-cluster node image${reset}"
      docker build -t=ekino/neo4j-cluster:latest node/
      ;;
    'run')
      mkdir -p $cnf
      # Start local DNS server
      echo -e "\n${cyan}==> Starting DNS server${reset}"
      docker run --name neodns -h neodns -v $(readlink -f $cnf):/etc/dnsmasq.d -d ekino/dnsmasq:latest
      localdns=$(docker inspect --format {{.NetworkSettings.IPAddress}} neodns)

      # From Neo4j manual : minimum 3 nodes is required => either start arbiter or call "run:3"
      echo -e "\n${cyan}==> Starting Neo4j cluster nodes + Registering to DNS server${reset}"
      nodes="${1#*:}"
      OIFS=$IFS
      IFS=","
      iter=0
      for node in $nodes
      do
        IFS=$OIFS
        iter=$((iter+1))
        datadir="$bdd/$node"
        mkdir -p $datadir
        # Create new cluster node
        echo "--> Run node '$node'"
        docker run --name $node -h $node --dns $localdns -e SERVER_ID=$iter -e CLUSTER_NODES=$nodes -v $(readlink -f $datadir):/var/lib/neo4j/data/  -P -d ekino/neo4j-cluster:latest
        # Add new node to DNS server
        echo "--> Register node '$node'"
        echo "host-record=$node,$(docker inspect --format {{.NetworkSettings.IPAddress}} $node)" | tee $cnf/50_docker_$node
        # Verify main settings
        echo "--> Verify main settings for '$node'"
        docker logs $node
      done

      # Restart DNS server to register new nodes
      echo -e "\n${cyan}==> Restarting DNS service${reset}"
      docker exec neodns supervisorctl restart dnsmasq

      # Wait.. and check last started node
      w=45
      echo -e "\n${cyan}==> Waiting ${w}s (cluster warmup)${reset}"
      sleep $w
      docker exec -ti $(docker ps -l | awk 'NR!=1{print $1}') curl http://localhost:7474

      # Display webadmin URLs
      echo -e "\n\n${cyan}==> Check each node's HA setup and availability using urls below${reset}"
      echo -e "${bgreen}"
      for i in $(docker ps | grep 7474 | sed -r 's/.*:(.....)->7474.*/\1/')
      do
        echo "http://localhost:$i/webadmin/#/info/org.neo4j/High%20Availability/"
      done
      echo -e "${reset}"
      ;;
    'clear')
      echo -e "\n${cyan}==> Killing running containers${reset}"
      docker kill $(docker ps | awk 'NR!=1{print $1}')
      echo -e "\n${cyan}==> Removing *all* containers${reset}"
      docker rm $(docker ps -a| awk 'NR!=1{print $1}')
      echo -e "\n${cyan}==> Cleaning all data files (dns + graphdb)${reset}"
      rm -f $cnf/*
      rm -rf "$bdd"
      echo -e "\n${cyan}==> Removing untagged/dangled images${reset}"
      [ "${1#*:}" = "all" ] && docker rmi $(docker images -f dangling=true | awk 'NR!=1{print $3}')
      ;;
  esac
  shift
done 3>&1 1>&2 2>&3 | awk '{print "'$red'" $0 "'$reset'"}'

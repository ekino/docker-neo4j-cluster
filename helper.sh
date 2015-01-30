#!/bin/bash
#set -x

command -v docker || curl http://get.docker.com/ | sh

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

      # Wait.. and check last started node
      w=45
      echo -e "\n${cyan}==> Waiting ${w}s (cluster warmup)${reset}"
      sleep $w
      docker exec -ti $(docker ps -lq) curl http://localhost:7474

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
      docker kill $(docker ps -q)
      echo -e "\n${cyan}==> Removing *all* containers${reset}"
      docker rm $(docker ps -aq)
      echo -e "\n${cyan}==> Cleaning all data files (dns + graphdb)${reset}"
      sudo rm -f $cnf/*
      sudo rm -rf "$bdd"
      echo -e "\n${cyan}==> Removing untagged/dangled images${reset}"
      [ "${1#*:}" = "all" ] && docker rmi $(docker images -qf dangling=true)
      ;;
    'inotify')
      # test the inotify on dnsmasq
      docker run --name neodns -h neodns -v $(readlink -f dns/dnsmasq.d):/etc/dnsmasq.d -d ekino/dnsmasq:latest
      localdns=$(docker inspect --format {{.NetworkSettings.IPAddress}} neodns)
      docker run --name neo1 -h neo1 --dns $localdns -e SERVER_ID=1 -e CLUSTER_NODES=neo1,neo2,neo3 -P -d ekino/neo4j-cluster:latest
      docker run --name neo2 -h neo2 --dns $localdns -e SERVER_ID=2 -e CLUSTER_NODES=neo1,neo2,neo3 -P -d ekino/neo4j-cluster:latest
      sleep 5
      echo "host-record=neo2,$(docker inspect --format {{.NetworkSettings.IPAddress}} neo2)" | tee dns/dnsmasq.d/50_docker_neo2
      sleep 5
      docker exec -t neodns cat /restartdns.log
      docker exec -t neo1 ping -c 4 neo2
  esac
  shift
done 3>&1 1>&2 2>&3 | awk '{print "'$red'" $0 "'$reset'"}'

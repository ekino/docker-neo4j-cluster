# ekino/neo4j-cluster

## Description

Get a Neo4J cluster in no time.

## Licensing

This repo uses Neo4J Enterprise, installed following the official and publicly
available page http://debian.neo4j.org/.

You **must** have a license to use Neo4J Enterprise, and as a consequence to use
this repo.

For more informations :
- Licenses :  http://neo4j.com/subscriptions/
- Contact : http://neo4j.com/contact-us/

## TL;DR

```bash
# start a neo4j cluster w/ 3 nodes
curl -sSL https://raw.githubusercontent.com/ekino/docker-neo4j-cluster/master/helper.sh | bash -s run:neomaster,neoreadslave,neobackup
```

## Cluster Creation

### Prerequisites

Clone the repo :
```bash
git clone git@github.com:ekino/docker-neo4j-cluster.git neo4j-cluster
cd neo4j-cluster
```

### Cluster initialisation (manual)

```bash
# Build dns server image (so nodes can communicate to each others)
docker build -t=ekino/dnsmasq:latest dns/

# Build neo4j-cluster node image
docker build -t=ekino/neo4j-cluster:latest node/

# Start dns server
docker run --name neodns -h neodns -v $(readlink -f dns/dnsmasq.d):/etc/dnsmasq.d -d ekino/dnsmasq:latest
localdns=$(docker inspect --format {{.NetworkSettings.IPAddress}} neodns)

# Start neo4j-cluster nodes
docker run --name neo1 -h neo1 --dns $localdns -e SERVER_ID=1 -e CLUSTER_NODES=neo1,neo2,neo3 -P -d ekino/neo4j-cluster:latest
docker run --name neo2 -h neo2 --dns $localdns -e SERVER_ID=2 -e CLUSTER_NODES=neo1,neo2,neo3 -P -d ekino/neo4j-cluster:latest
docker run --name neo3 -h neo3 --dns $localdns -e SERVER_ID=3 -e CLUSTER_NODES=neo1,neo2,neo3 -P -d ekino/neo4j-cluster:latest

# Register nodes to dns server
echo "host-record=neo1,$(docker inspect --format {{.NetworkSettings.IPAddress}} neo1)" | tee dns/dnsmasq.d/50_docker_neo1
echo "host-record=neo2,$(docker inspect --format {{.NetworkSettings.IPAddress}} neo2)" | tee dns/dnsmasq.d/50_docker_neo2
echo "host-record=neo3,$(docker inspect --format {{.NetworkSettings.IPAddress}} neo3)" | tee dns/dnsmasq.d/50_docker_neo3
docker exec neodns supervisorctl restart dnsmasq

# Check your host ports forwared to 7474 for each nodes
docker ps

# For each forwared port go to
http://localhost:<FORWARDED_PORT>/webadmin/#/info/org.neo4j/High%20Availability/
```

### Cluster initialisation (auto)

`WARNING: Before you proceed, be aware the 'clear' argument kills and rm all docker containers !`

For convinience, you can use the helper.sh file to remove old or running container, build new images,
start the new containers and/or check the cluster configuration.

Arguments :
- `clear`: kill running containers + remove all containers
- `clear:all`: same as `clear` + remove untagged/dangled images
- `build`: build `ekino/dnsmasq` and `ekino/neo4j-cluster` images
- `run:NODES`: run all listed NODES (comma separated)

Arguments can be added to the commandline. They will be processed in order.

```bash
# oneline command equivalent to manual install above : (/!\ it remove all your containers /!\)
./helper.sh clear:all build run:neo1,neo2,neo3
```

## Cluster Usage

Either use `neo4j-shell` command, http dashboard or rest api...

## The End ?

For this POC, we have used `dnsmasq` so the nodes can talk to each other.
but we could have used more complex but powerful tools like `etcd`, `consul`, ....

Next, we'll talk about data persistence and neo4j extensions.

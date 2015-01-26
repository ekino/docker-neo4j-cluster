# --- NEO4J CLUSTER ---

FROM ubuntu:trusty
MAINTAINER Matthieu Fronton <fronton@ekino.com>
ENV DEBIAN_FRONTEND noninteractive

# required tools
RUN apt-get update
RUN apt-get install -y wget curl

# install neo4j
RUN wget -O - http://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
RUN echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list
RUN apt-get update -y
RUN apt-get install -y neo4j-enterprise neo4j-arbiter supervisor

# cleanup
RUN apt-get autoremove -y wget
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# configure
ADD start.sh /start.sh
ADD supervisord.conf /etc/supervisor/conf.d/neo4j.conf
ADD neo4j.properties /etc/neo4j/neo4j.properties
#ADD neo4j-server.properties /etc/neo4j/neo4j-server.properties

ENV REMOTE_HTTP true
ENV REMOTE_SHELL true

EXPOSE 5001
EXPOSE 6001
EXPOSE 7474

CMD ["/start.sh"]
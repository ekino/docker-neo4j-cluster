# --- NEO4J CLUSTER ---

FROM ekino/base
MAINTAINER Matthieu Fronton <fronton@ekino.com>

ENV DEBIAN_FRONTEND noninteractive
ENV NEO4J_VERSION 2.1.7

# install neo4j
RUN curl -sSL http://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
RUN echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list
RUN apt-get update -y && apt-get install -y neo4j-enterprise=$NEO4J_VERSION neo4j-arbiter=$NEO4J_VERSION supervisor

# cleanup
RUN apt-get autoremove -y wget
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# configure
RUN touch /root/.neo4j_shell_history
ADD supervisord.conf /etc/supervisor/conf.d/neo4j.conf
ADD neo4j.properties /etc/neo4j/neo4j.properties
#ADD neo4j-server.properties /etc/neo4j/neo4j-server.properties

ENV REMOTE_HTTP true
ENV REMOTE_SHELL true

EXPOSE 5001
EXPOSE 6001
EXPOSE 7474

# startup
ADD neo4j.sh /start.d/10-neo4j
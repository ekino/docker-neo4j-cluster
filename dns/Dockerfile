# --- DNSMASQ ---

FROM ubuntu:trusty
MAINTAINER Matthieu Fronton <fronton@ekino.com>
ENV DEBIAN_FRONTEND noninteractive

# required tools
RUN apt-get update
RUN apt-get install -y supervisor

# install dnsmasq
RUN apt-get install -y dnsmasq inotify-tools

# cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# configure
ADD supervisord.conf /etc/supervisor/conf.d/dnsmasq.conf
ADD dnsmasq.conf /etc/dnsmasq.conf
ADD dnsmasq.d /etc/dnsmasq.d
ADD start.sh /start.sh

ADD restartdns.sh /restartdns.sh

EXPOSE 53

CMD ["/start.sh"]
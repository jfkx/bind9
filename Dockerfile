FROM debian:stretch-slim
LABEL author="Filip Krajcovic"
LABEL date="28.06.2021"
LABEL version="1.0"

ENV LC_ALL C.UTF-8

# environemnt file
COPY ./env.sh /etc/profile.d/

RUN set -e \
&& ln -snf /usr/share/zoneinfo/Europe/Prague /etc/localtime && echo "Europe/Prague" > /etc/timezone \
&& apt-get update \
&& apt-get -y upgrade \
&& apt-get -y install wget telnet vim curl jq git httpie \
&& apt-get -y install dnsutils procps bash inetutils-ping \
&& apt-get -y install ca-certificates apt-transport-https locales \
&& locale-gen cs_CZ.UTF-8 

# entrypoint script
COPY ./entrypoint.sh /tmp/entrypoint.sh

RUN chmod a+x /tmp/entrypoint.sh \
&& echo "set mouse-=a" >> /root/.vimrc 

RUN apt-get -y install bind9 bind9-doc

RUN apt-get -y autoremove \
&& apt-get -y clean



# VOLUME ["/etc/bind", "/var/cache/bind", "/var/lib/bind", "/var/log"]

# RUN mkdir -p /etc/bind && chown root:bind /etc/bind/ && chmod 755 /etc/bind
# RUN mkdir -p /var/cache/bind && chown bind:bind /var/cache/bind && chmod 755 /var/cache/bind
# RUN mkdir -p /var/lib/bind && chown bind:bind /var/lib/bind && chmod 755 /var/lib/bind
# RUN mkdir -p /var/log/bind && chown bind:bind /var/log/bind && chmod 755 /var/log/bind
# RUN mkdir -p /run/named && chown bind:bind /run/named && chmod 755 /run/named

EXPOSE 53/udp 53/tcp 953/tcp


ENTRYPOINT ["/tmp/entrypoint.sh"];
#CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
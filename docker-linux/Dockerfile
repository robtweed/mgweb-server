# mg_web + YottaDB for Linux

# Dockerised version of mg_web with YottaDB, using Apache

# M/Gateway Developments Ltd
# 7 December 2020

FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
  curl \
  build-essential \
  make \
  gcc \
  git \
  wget \
  dos2unix \
  locate \
  nano \
  xinetd \
  apache2 \
  apache2-utils \
  apache2-dev \
  libelf1 \
  libtinfo5 \
  lsof

# Create app directory
RUN mkdir -p /opt/mgweb \
 && mkdir /opt/mg_web  \
 && mkdir /opt/mgweb/m \
 && mkdir /opt/yottadb

WORKDIR /opt/mgweb

# Get mg-web

RUN git clone https://github.com/chrisemunt/mg_web  \
 && cp /opt/mgweb/mg_web/src/*.h /opt/mg_web \
 && cp /opt/mgweb/mg_web/src/*.c /opt/mg_web \
 && cp /opt/mgweb/mg_web/src/apache/* /opt/mg_web \
 && cd /opt/mg_web \
 && dos2unix *

RUN cd /opt/mg_web \
 && apxs -a -i -c mg_web_apache.c mg_web.c mg_websocket.c

# Copy files from the current Docker directory
# and make any scripts executable

COPY . /opt/mgweb
RUN dos2unix /opt/mgweb/* \
 && mv /opt/mgweb/index.html /var/www/html \
 && chmod +x /opt/mgweb/ydb \
 && chmod +x /opt/mgweb/ydb_run \
 && chmod +x /opt/mgweb/ydb_run_temp \
 && chmod +x /opt/mgweb/start \
 && chmod +x /opt/mgweb/stop \
 && chmod +x /opt/mgweb/reconfigure \
 && chmod +x /opt/mgweb/build_routes \
 && chmod +x /opt/mgweb/restart

# Fetch the generic mg_web server repository
# and move its M code and mg_web conf and log
# files into place 

RUN git clone https://github.com/robtweed/mgweb-server /opt/mgweb/server \
  && mv /opt/mgweb/server/m/* /opt/mgweb/m/ \
  && mv /opt/mgweb/server/config/mgweb.conf.json /opt/mgweb/mgweb.conf.json \
  && mv /opt/mgweb/server/config/mgweb.log /opt/mgweb \
  && cp /opt/mgweb/server/apache/apache2.conf /etc/apache2 \
  && cp /opt/mgweb/server/apache/ports.conf /etc/apache2 \
  && cp /opt/mgweb/server/apache/mpm_event.conf /opt/mgweb \
  && chown www-data:www-data /opt/mgweb/*

RUN echo "Installing YottaDB..."

RUN mkdir /tmp/tmp \
  && wget -P /tmp/tmp https://gitlab.com/YottaDB/DB/YDB/raw/master/sr_unix/ydbinstall.sh \
  && cd /tmp/tmp \
  && chmod +x ydbinstall.sh \
  && ./ydbinstall.sh --utf8 default --verbose --force-install \
  && export ydb_gbldir=/opt/yottadb/yottadb.gld \
  && /usr/local/lib/yottadb/r130/mumps -run ^GDE < /opt/mgweb/gde.txt \
  && /usr/local/lib/yottadb/r130/mupip create

# Install and configure the network mgsi interface code to allow
# network access to YottaDB (default setup uses
# API access to YottaDB)

RUN git clone https://github.com/chrisemunt/mgsi /opt/mgweb/mgsi \
  && cp /opt/mgweb/mgsi/yottadb/* /opt/mgweb/m \
  && /opt/mgweb/ydb_run_temp ylink^%zmgsi \
  && rm -r /opt/mgweb/mgsi \
  && cp /opt/mgweb/mg_web/unix/zmgsi.ci /usr/local/lib/yottadb/r130

# Set up the xinetd interface for optional network access
# to YottaDB

RUN cp /opt/mgweb/mg_web/unix/zmgsi_ydb /usr/local/lib/yottadb/r130 \
  && cp /opt/mgweb/mg_web/unix/zmgsi_xinetd /etc/xinetd.d/zmgsi_xinetd \
  && cp /opt/mgweb/mg_web/unix/zmgsi.ci /usr/local/lib/yottadb/r130 \
  && sed -i 's/122/130/g' /etc/xinetd.d/zmgsi_xinetd \
  && sed -i 's/122/130/g' /usr/local/lib/yottadb/r130/zmgsi_ydb \
  && sed -i 's/1.22/1.30/g' /usr/local/lib/yottadb/r130/zmgsi_ydb \
  && echo "zmgsi_xinetd          7041/tcp                        # zmgsi" >> /etc/services

# Pre-load the %zmgweb* routines to prevent
# IRIS-specific code generating warnings during startup

RUN chown -R www-data:www-data /opt/mgweb/m \
  && /opt/mgweb/ydb_run_temp ylink^%zmgweb \
  && rm ydb_run_temp

# Clean up

RUN rm /opt/mgweb/Dockerfile \
  && rm -r /opt/mgweb/gde.txt \
  && rm -r /opt/mgweb/server

RUN updatedb

RUN cd /opt/mgweb

EXPOSE 8080

# When container starts, start Apache etc
# and tail the Apache access log

CMD [ "/bin/bash", "./start" ]

# ENTRYPOINT ["/bin/bash"]

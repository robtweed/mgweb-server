# mg_web + YottaDB for Linux

# Dockerised version of mg_web with YottaDB, using Apache

# Copyright 2023, MGateway Ltd
# 11 August 2022

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
  lsof \
  libssl-dev

# Create app directory
RUN mkdir -p /opt/mgweb \
 && mkdir /opt/mg_web  \
 && mkdir /opt/mgweb/m \
 && mkdir /opt/yottadb

WORKDIR /opt/mgweb

# Get mg-web

RUN echo "Installing mg_web.."

RUN git clone https://github.com/chrisemunt/mg_web  \
 && cp /opt/mgweb/mg_web/src/*.h /opt/mg_web \
 && cp /opt/mgweb/mg_web/src/*.c /opt/mg_web \
 && cp /opt/mgweb/mg_web/src/apache/* /opt/mg_web \
 && cd /opt/mg_web \
 && dos2unix *

RUN cd /opt/mg_web \
 && apxs -a -i -c mg_web_apache.c mg_web.c mg_webstatus.c mg_webtls.c mg_websocket.c

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

RUN echo "Installing mgweb-server files"

RUN git clone https://github.com/robtweed/mgweb-server /opt/mgweb/server \
  && mv /opt/mgweb/server/m/* /opt/mgweb/m/ \
  && mv /opt/mgweb/_zmgewd.m /opt/mgweb/m/_zmgewd.m \
# && cp /opt/mgweb/mgweb.conf.json /opt/mgweb/mgweb.conf \
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
  && /usr/local/lib/yottadb/r134/mumps -run ^GDE < /opt/mgweb/gde.txt \
  && /usr/local/lib/yottadb/r134/mupip create

# Install EWD Routines into /opt/mgweb/m

RUN echo "Loading EWD Routine files..."

RUN git clone https://github.com/robtweed/EWD /opt/mgweb/ewd \
  && cp /opt/mgweb/ewd/*.m /opt/mgweb/m \
  && rm -r /opt/mgweb/ewd \
  && cd /opt/mgweb/m \
  && dos2unix *

# Install and configure the network mgsi interface code to allow
# network access to YottaDB (default setup uses
# API access to YottaDB)

RUN git clone https://github.com/chrisemunt/mgsi /opt/mgweb/mgsi \
  && cp /opt/mgweb/mgsi/yottadb/* /opt/mgweb/m \
  && /opt/mgweb/ydb_run_temp ylink^%zmgsi \
  && cp /opt/mgweb/mgsi/unix/zmgsi.ci /usr/local/lib/yottadb/r134 \
  && rm -r /opt/mgweb/mgsi

# Set up the xinetd interface for optional network access
# to YottaDB

#RUN cp /opt/mgweb/mgsi/unix/zmgsi_ydb /usr/local/lib/yottadb/r134 \
#  && cp /opt/mgweb/mgsi/unix/zmgsi_xinetd /etc/xinetd.d/zmgsi_xinetd \
#  && cp /opt/mgweb/mgsi/unix/zmgsi.ci /usr/local/lib/yottadb/r134 \
#  && sed -i 's/130/134/g' /etc/xinetd.d/zmgsi_xinetd \
#  && sed -i 's/130/134/g' /usr/local/lib/yottadb/r134/zmgsi_ydb \
#  && sed -i 's/1.30/1.34/g' /usr/local/lib/yottadb/r134/zmgsi_ydb \
#  && echo "zmgsi_xinetd          7041/tcp                        # zmgsi" >> /etc/services \
#  && rm -r /opt/mgweb/mgsi


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

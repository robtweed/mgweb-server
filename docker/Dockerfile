# mg_web + YottaDB

# Dockerised version of mg_web with YottaDB, using NGINX

# M/Gateway Developments Ltd
# 4 November 2020

#FROM ubuntu:20.04
FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y

RUN apt install -y \
  software-properties-common \
  ufw \
  build-essential \
  git \
  tree \
  perl \
  libperl-dev \
  libgd3 \
  libgd-dev \
  libgeoip1 \
  libgeoip-dev \
  geoip-bin \
  libxml2 \
  libxml2-dev \
  libxslt1.1 \
  libxslt1-dev \
  libssl-dev \
  dos2unix \
  wget \
  gzip \
  openssh-server \
  curl \
  libelf1 \
  locate \
  nano \
  subversion \
  xinetd \
  libtinfo5 \
  apache2-utils

# ========= Install Node.js for good measure

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 14.15.0

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    1C050899334244A8AF75E53792EF661D867B9DFA \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version

ENV YARN_VERSION 1.22.5

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  # smoke test
  && yarn --version
# =========

# Create app directory
RUN mkdir -p /opt/mgweb
WORKDIR /opt/mgweb

RUN echo "Installing YottaDB..."

RUN mkdir /tmp/tmp \
  && wget -P /tmp/tmp https://gitlab.com/YottaDB/DB/YDB/raw/master/sr_unix/ydbinstall.sh \
  && cd /tmp/tmp \
  && chmod +x ydbinstall.sh \
  && ./ydbinstall.sh --utf8 default --verbose \
  && /bin/bash -c "source /usr/local/lib/yottadb/r130/ydb_env_set"

RUN cd ~

RUN echo "Installing NGINX"

RUN wget https://nginx.org/download/nginx-1.18.0.tar.gz && tar zxvf nginx-1.18.0.tar.gz
# PCRE version 8.44
RUN wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz

# zlib version 1.2.11
RUN wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz

# OpenSSL version 1.1.1g
RUN wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz && tar xzvf openssl-1.1.1g.tar.gz

RUN rm -rf *.tar.gz

# Get mg-web

RUN mkdir /opt/mg_web
RUN git clone https://github.com/chrisemunt/mg_web
RUN cp /opt/mgweb/mg_web/src/*.h /opt/mg_web
RUN cp /opt/mgweb/mg_web/src/*.c /opt/mg_web
RUN cp /opt/mgweb/mg_web/src/nginx/* /opt/mg_web
RUN cd /opt/mg_web \
  && dos2unix *

RUN cd /opt/mgweb/nginx-1.18.0 \
 && ./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=root \
            --group=root \
            --build=Ubuntu \
            --builddir=nginx-1.18.0 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.44 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1g \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug \
            --add-module=/opt/mg_web \
  && make \
  && make install

RUN cd /opt/mgweb
RUN ln -s /usr/lib/nginx/modules /etc/nginx/modules \
 && nginx -V

RUN adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx
# Check that user and group are created
RUN tail -n 1 /etc/passwd /etc/group /etc/shadow


# Create NGINX cache directories and set proper permissions
RUN mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp \
 && chmod 700 /var/cache/nginx/* \
 && chown nginx:nginx /var/cache/nginx/* \
 && chown -R nginx:nginx /var/log/nginx

RUN git clone https://github.com/robtweed/wc-conduit /opt/mgweb/wc-conduit \
  && mv /opt/mgweb/wc-conduit/components /etc/nginx/html/ \
  && mv /opt/mgweb/wc-conduit/conduit-wc /etc/nginx/html/

RUN git clone https://github.com/robtweed/mg-webComponents /opt/mgweb/mg-webComponents \
  && mv /opt/mgweb/mg-webComponents/mg-webComponents.js /etc/nginx/html/

# Re-check syntax and potential errors. 
RUN nginx -t

# Bundle app source
COPY . /opt/mgweb
RUN chmod +x /opt/mgweb/ydb \
 && chmod +x /opt/mgweb/ydb_run \
 && chmod +x /opt/mgweb/ydb_run_temp \
 && chmod +x /opt/mgweb/start \
 && chmod +x /opt/mgweb/restart

RUN cp /opt/mgweb/nginx.conf /etc/nginx \
 && cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default \
 && chown -R nginx:nginx /etc/nginx \
 && chown nginx:nginx /opt/mgweb/*
 # && chown -R nginx:nginx /opt/mgweb/mgweb.log
 # && chmod -R 755 /opt/mgweb

RUN touch /var/run/nginx.pid \
  && chown -R nginx:nginx /var/run/nginx.pid

RUN mkdir /opt/mgweb/m

RUN git clone https://github.com/chrisemunt/mgsi /opt/mgweb/mgsi \
  && cp /opt/mgweb/mgsi/yottadb/* /opt/mgweb/m \
  && /opt/mgweb/ydb_run_temp ylink^%zmgsi \
  && rm -r /opt/mgweb/mgsi

RUN cp /opt/mgweb/mg_web/unix/zmgsi_ydb /usr/local/lib/yottadb/r130 \
  && cp /opt/mgweb/mg_web/unix/zmgsi_xinetd /etc/xinetd.d/zmgsi_xinetd \
  && cp /opt/mgweb/mg_web/unix/zmgsi.ci /usr/local/lib/yottadb/r130 \
  && sed -i 's/122/130/g' /etc/xinetd.d/zmgsi_xinetd \
  && sed -i 's/122/130/g' /usr/local/lib/yottadb/r130/zmgsi_ydb \
  && sed -i 's/1.22/1.30/g' /usr/local/lib/yottadb/r130/zmgsi_ydb \
  && echo "zmgsi_xinetd          7041/tcp                        # zmgsi" >> /etc/services

RUN mv /opt/mgweb/_zmgweb.m /opt/mgweb/m \
  && mv /opt/mgweb/_zmgwebJWT.m /opt/mgweb/m \
  && mv /opt/mgweb/_zmgwebUtils.m /opt/mgweb/m \
  && chmod 777 /opt/mgweb/m/* \
  && /opt/mgweb/ydb_run_temp ylink^%zmgweb \
  && rm ydb_run_temp

RUN rm /opt/mgweb/Dockerfile \
  && rm /opt/mgweb/nginx.conf \
  && rm /opt/mgweb/build.txt \
  && rm -r /opt/mgweb/openssl-1.1.1g \
  && rm -r /opt/mgweb/wc-conduit \
  && rm -r /opt/mgweb/pcre-8.44 \
  && rm -r /opt/mgweb/mg-webComponents \
  && rm -r /opt/mgweb/nginx-1.18.0 \
  && rm -r /opt/mgweb/zlib-1.2.11

RUN cd /opt/mgweb

EXPOSE 8080

# ENTRYPOINT ["/bin/bash", "./start"]

CMD [ "/bin/bash", "./start" ]

# CMD [ "/bin/bash", "nginx", "-c", "/etc/nginx/nginx.conf" ]

# CMD [ "nginx", "-g", "daemon off;" ]
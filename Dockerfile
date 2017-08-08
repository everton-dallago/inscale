#
# Dockerfile para testes com modulos de nginx
#
FROM dockerfile/ubuntu
MAINTAINER Cristiano Barros <cb@inscale.com.br>

ENV NGINX_VERSION 1.10.1
# Perl-Compatible Regular Expressions
ENV PCRE_VERSION 8.38
ENV ZLIB_VERSION 1.2.8

ENV BUILDDIR /build
ENV NGINXDIR ${BUILDDIR}/nginx-${NGINX_VERSION}
ENV MODULESDIR ${NGINXDIR}/3rdparty

# Get noninteractive frontend for Debian to avoid some problems:
#     debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

# PHP7 ppa
RUN apt-get install -y language-pack-en-base software-properties-common
RUN LC_ALL=en_US.UTF-8 apt-add-repository ppa:ondrej/php

# After adding the PHP7 ppa, update lists and upgrade
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y autoremove

# Install Supervisor (docker)
RUN apt-get -y install python-setuptools
RUN easy_install supervisor

# Basic daily-use support packages
RUN apt-get install -y curl git htop man unzip vim wget netcat

# Build packages
RUN apt-get install -y build-essential
RUN apt-get install -y libtool automake autoconf autogen

###
# Install Stack
###

## Install packages
RUN apt-get install -y \
    php7.0-dev \
    php7.0-fpm \
    php7.0-gd \
    php7.0-mysql \
    php7.0-opcache \
    php7.0-zip
    # memcached

ENV BUILDDIR /build

## Build dependencies
WORKDIR ${BUILDDIR}
RUN wget -q --tries=2 --waitretry=1 --read-timeout=20 --timeout=15 --continue http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz
RUN wget -q --tries=2 --waitretry=1 --read-timeout=20 --timeout=15 --continue http://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz \
    && tar -xzf pcre-${PCRE_VERSION}.tar.gz

## Build nginx
WORKDIR $NGINXDIR
RUN ./configure \
    --prefix=/usr/share/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-threads \
    --user=www-data \
    --group=www-data \
    --with-debug \
    --without-http_gzip_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --without-http_scgi_module \
    && make && make install

# Make sure the default PHP socket path exists
RUN mkdir -p /run/php

# instala o composer - ver esse comando
#RUN php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php \
#    && php composer-setup.php && php -r "unlink('composer-setup.php');" \
#    && mv composer.phar /usr/local/bin/composer

COPY etc/php/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf

### Docker-related and runtime configurations

## Add runtime scripts
COPY runtime /runtime
RUN chmod 755 /runtime/*.sh

# Copy conf files
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY html/* /html/
COPY /etc/php/7.0/* /etc/php/7.0/
COPY /var/log/* /var/log/nginx/

WORKDIR /usr/share/nginx/html
CMD ["/runtime/entrypoint.sh" ]
ENTRYPOINT ["/runtime/run.sh"]

FROM debian:jessie

#PACKAGES
RUN apt-get update -y && apt-get install -y wget curl;

RUN echo deb http://packages.dotdeb.org jessie all >> /etc/apt/sources.list \
    && echo deb-src http://packages.dotdeb.org jessie all >> /etc/apt/sources.list \
    && wget https://www.dotdeb.org/dotdeb.gpg -q \
    && apt-key add dotdeb.gpg \
    && rm dotdeb.gpg \
    && apt-get update -y \
    && apt-get install -y \
        php7.0 \
        php7.0-fpm \
        php7.0-mbstring \
        php7.0-gd \
        php7.0-intl \
        php7.0-curl \
        php7.0-cli \
        php7.0-mcrypt \
        php7.0-xml \
        php7.0-common \
        php7.0-mysql \
        php7.0-pgsql \
        php7.0-sqlite \
        nginx \
        supervisor \
    && mkdir -p /var/log/supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get --purge autoremove -y

#CONFIG PHP
RUN sed -i 's/^max_execution_time *= *.*$/max_execution_time = 0/g' /etc/php/7.0/cli/php.ini
RUN sed -i 's/^ *;\? *date.timezone *=.*$/date.timezone = UTC/g' /etc/php/7.0/cli/php.ini
RUN sed -i "s/^ *variables_order *= *\"GPCS\" *$/variables_order = \"EGPCS\"/" /etc/php/7.0/cli/php.ini
RUN sed -i 's/^ *;\? *date.timezone *=.*$/date.timezone = UTC/g' /etc/php/7.0/fpm/php.ini
RUN sed -i "s/^ *variables_order *= *\"GPCS\" *$/variables_order = \"EGPCS\"/" /etc/php/7.0/fpm/php.ini
RUN sed -Ei "s/^ *;?listen.mode *=.*$/listen.mode = 0664/" /etc/php/7.0/fpm/pool.d/www.conf

RUN mkdir -p /run/php

#INSTALL COMPOSER
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

#CONFIG NGINX
ADD config/laravel /etc/nginx/sites-available/laravel

RUN sed -i "s/^\( *\)worker_connections \+[0-9]\+; *$/\1worker_connections 1024;/" /etc/nginx/nginx.conf
RUN sed -i "s/^\( *\)keepalive_timeout \+[0-9]\+; *$/\1keepalive_timeout 1200;/" /etc/nginx/nginx.conf

RUN ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel \
    && rm /etc/nginx/sites-enabled/default

RUN ln -sf /dev/stderr /var/log/nginx/error.log
    
ADD ./config/.bashrc /root/.bashrc
ADD config/supervisord.conf /etc/supervisord.conf
ADD config/docker-entrypoint.sh /root/docker-entrypoint.sh

RUN chmod +x /root/docker-entrypoint.sh

EXPOSE 80 443

WORKDIR /var/www

RUN rm -rf /var/www/html

ENTRYPOINT ["/root/docker-entrypoint.sh"]
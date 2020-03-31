FROM php:7.3-fpm
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        zlib1g-dev \
        libpq-dev \
        libicu-dev \
        libmcrypt-dev \
        libxml2-dev \
        libmagickwand-dev \
        libcurl4-gnutls-dev \
        g++ \
        wget \
        curl \
        vim \
        cron \
        openssl \
        nginx \
        supervisor

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-enable intl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-enable bcmath \
    && docker-php-ext-install soap \
    && docker-php-ext-enable soap \
    && docker-php-ext-install curl \
    && docker-php-ext-enable curl

RUN pecl install imagick \
    && docker-php-ext-enable imagick

RUN pecl install -o -f mcrypt-1.0.2 \
    && docker-php-ext-enable mcrypt

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

RUN echo 'xdebug.default_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_port=9001' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_connect_back=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.idekey=sublime.xdebug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_autostart=false' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_log="/tmp/xdebug.log"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apt-get install -f -y \
    && apt-get --purge autoremove -y;

# INSTALL COMPOSER
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# CONFIG LOCALE
#RUN mv /etc/locale.gen /etc/locale.gen.bkp \
#    && echo "pt_BR UTF-8" > /etc/locale.gen \
#    && echo "en_US UTF-8" >> /etc/locale.gen \
#    && grep -qE "^pt_BR " /etc/locale.alias || echo "pt_BR pt_BR.UTF-8" >> /etc/locale.alias \
#    && locale-gen --purge
#CONFIG PHP
# RUN sed -i 's/^max_execution_time *= *.*$/max_execution_time = 0/g' /usr/local/etc/php/php.ini
# RUN sed -i 's/^ *;\? *date.timezone *=.*$/date.timezone = UTC/g' /usr/local/etc/php/php.ini
# RUN sed -i "s/^ *variables_order *= *\"GPCS\" *$/variables_order = \"EGPCS\"/" /usr/local/etc/php/php.ini
# RUN sed -i "s/^ *memory_limit *= *[0-9]\+M *$/memory_limit = 512M/" /usr/local/etc/php/php.ini
# RUN sed -i "s/^ *post_max_size *= *[0-9]\+M *$/post_max_size = 50M/" /usr/local/etc/php/php.ini
# RUN sed -i 's/^ *;\? *date.timezone *=.*$/date.timezone = UTC/g' /usr/local/etc/php-fpm.d/www.conf
# RUN sed -i "s/^ *variables_order *= *\"GPCS\" *$/variables_order = \"EGPCS\"/" /usr/local/etc/php-fpm.d/www.conf
# RUN sed -i "s/^ *memory_limit *= *[0-9]\+M *$/memory_limit = 512M/" /usr/local/etc/php-fpm.d/www.conf
# RUN sed -i "s/^ *post_max_size *= *[0-9]\+M *$/post_max_size = 50M/" /usr/local/etc/php-fpm.d/www.conf
# RUN sed -Ei "s/^ *;?listen.mode *=.*$/listen.mode = 0664/" /etc/php/7.2/fpm/pool.d/www.conf
# RUN mkdir -p /run/php

# CONFIG NGINX
RUN echo "fastcgi_pass 127.0.0.1:9000;\n\n$(cat /etc/nginx/snippets/fastcgi-php.conf)" > /etc/nginx/snippets/fastcgi-php.conf

#ADD config/laravel /etc/nginx/sites-available/laravel
#RUN ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel

# RUN sed -i "s/^\( *\)worker_connections \+[0-9]\+; *$/\1worker_connections 1024;/" /etc/nginx/nginx.conf
# RUN sed -i "s/^\( *\)keepalive_timeout \+[0-9]\+; *$/\1keepalive_timeout 1200;/" /etc/nginx/nginx.conf

RUN rm /etc/nginx/sites-enabled/default
RUN ln -sf /dev/stderr /var/log/nginx/error.log

ADD ./config/.bashrc /root/.bashrc

# Set up cron
#ADD ./config/crontab /var/spool/cron/crontabs/www-data
#RUN chown www-data.crontab /var/spool/cron/crontabs/www-data
#RUN chmod 0600 /var/spool/cron/crontabs/www-data

# CONFIG SUPERVISOR
RUN mkdir -p /var/log/supervisor
ADD config/supervisord.conf /etc/supervisord.conf

ADD config/docker-entrypoint.sh /root/docker-entrypoint.sh
RUN chmod +x /root/docker-entrypoint.sh

RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data
RUN rm -rf /var/www/html

EXPOSE 80 443
WORKDIR /var/www

ENTRYPOINT ["/root/docker-entrypoint.sh"]
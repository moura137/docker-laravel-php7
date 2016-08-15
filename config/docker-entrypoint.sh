#!/bin/bash

# # Function to update the fpm configuration to make the service environment variables available
echo "[www]" > /etc/php/7.0/fpm/pool.d/environments.conf
for curVar in `env | grep -Ev "^(\_|PWD|OLDPWD|PATH|SHLVL|HOME|HOSTNAME)=" | awk -F = '{print $1}'`;do
    echo "env[${curVar}] = ${!curVar}" >> /etc/php/7.0/fpm/pool.d/environments.conf
done

chgrp www-data -R /var/www/storage /var/www/bootstrap/cache
chmod 775 /var/www/storage /var/www/bootstrap/cache
/usr/bin/supervisord -n -c /etc/supervisord.conf
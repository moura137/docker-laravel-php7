#!/bin/bash
set -e

# Set # of hard links to 1 to keep cron happy.
touch /etc/cron.d/php7 /var/spool/cron/crontabs/www-data /etc/crontab

# Function to update the fpm configuration to make the service environment variables available
# echo "[www]" > /usr/local/etc/php-fpm.d/environments.conf
# for curVar in `env | grep -Ev "^(\_|PWD|OLDPWD|PATH|SHLVL|HOME|HOSTNAME)=" | awk -F = '{print $1}'`;do
    # echo "env[${curVar}] = ${!curVar}" >> /usr/local/etc/php-fpm.d/environments.conf
# done

#chgrp www-data -R /var/www/storage /var/www/bootstrap/cache
#chmod 775 /var/www/storage /var/www/bootstrap/cache
/usr/bin/supervisord -n -c /etc/supervisord.conf
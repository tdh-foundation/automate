#!/bin/bash

## Loading config
if [ "${CONFIG[NAME]}" == "" ]; then source ./loadconfig.sh; fi
echo "Starting cleaning configuration for ${CONFIG[NAME]}..."

##
## mariaDB Section
##
if [ "${CONFIG[DB_NAME]}" == "" ]; then CONFIG[DB_NAME]+=${CONFIG[NAME]}; fi
if [ "${CONFIG[DB_USER]}" == "" ]; then CONFIG[DB_USER]+=${CONFIG[NAME]}; fi
echo "Removing database and user ${CONFIG[DB_NAME]}..."
sudo mysql -e "drop user '${CONFIG[DB_USER]}'@'localhost';"
sudo mysql -e "drop database ${CONFIG[DB_NAME]};"

##
## NGINX Section
##
echo "Removing NGINX configuration file and reload NGINX"
sudo rm -f /etc/nginx/sites-available/${CONFIG[NAME]}
sudo rm -f /etc/nginx/sites-enabled/${CONFIG[NAME]}
sudo rm -f /etc/nginx/snippets/${CONFIG[NAME]}.conf

sudo certbot revoke --cert-path /etc/letsencrypt/live/${CONFIG[SERVER]}/cert.pem --reason superseded
sudo certbot delete --cert-name ${CONFIG[SERVER]} 
sudo rm -fR  /etc/letsencrypt/live/${CONFIG[SERVER]}

RESULT=$(sudo nginx -t)
if [ $? == 0 ]; then sudo systemctl reload nginx.service; fi

##
## PHP fpm configuration
##
echo "Removing PHP fpm instance..."
sudo rm -f /etc/php/7.3/fpm/pool.d/${CONFIG[NAME]}.conf
sudo systemctl restart php7.3-fpm.service

###
### Removing site files
###
sudo rm -fR /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}
unset CONFIG
unset RESULT
#!/bin/bash

## Loading config
source ./loadconfig.sh
echo "Starting configuration for ${CONFIG[NAME]}..."

##
## mariaDB/mySQL Section
##
echo "Creating Database ${CONFIG[DB_NAME]}..."

## Creating database if DB already exist throwing an error
RESULT=$(sudo mysqlshow | sed -nE "s/^\|\s(${CONFIG[DB_NAME]})\s+\|$/\1/pi")
if [ "$RESULT" != "" ];then
    echo "Error: Database ${CONFIG[DB_NAME]} already exist..."
    unset CONFIG
    unset RESULT
    exit 1
fi
sudo mysql -e "CREATE DATABASE ${CONFIG[DB_NAME]};"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${CONFIG[DB_NAME]}.* TO '${CONFIG[DB_USER]}'@'localhost' IDENTIFIED BY '${CONFIG[DB_PASSWORD]}';"

###
### PHP fpm configuration
###
echo "Configuring PHP fpm instance and reload them..."
cat ${CONFIG[FPM_TPL]} | sed -E  "s/§NAME§/${CONFIG[NAME]}/gm" | sudo tee /etc/php/7.3/fpm/pool.d/${CONFIG[NAME]}.conf >/dev/null
sudo systemctl reload php7.3-fpm.service

##
## NGINX Configuration
##
## Creating NGINX configuration file
echo "Creating NGINX configuration..."
cat ${CONFIG[NGINX_TPL]} | sed -E "s/§ROOT§/${CONFIG[SITES_ROOT]}/gm" | sed -E "s/§NAME§/${CONFIG[NAME]}/gm" | sed -E "s/§SERVER§/${CONFIG[SERVER]}/gm" | sudo tee /etc/nginx/sites-available/${CONFIG[NAME]} >/dev/null
sudo ln -s /etc/nginx/sites-available/${CONFIG[NAME]} /etc/nginx/sites-enabled/${CONFIG[NAME]}
sudo cp ${CONFIG[NGINX_SNIPPETS]} /etc/nginx/snippets/${CONFIG[NAME]}.conf
RESULT=$(sudo nginx -t)

## if something is wrong with NGINX conf rollback all previous operations
if [ $? != 0 ];then
    echo "Error: NGINX configuration file error."
    ./clean.sh $1
    unset CONFIG
    unset RESULT
    exit 1
fi
## Everything seems be Ok with NGINX reloading configuration
sudo systemctl reload nginx.service

##
## Installing Let's Encrypt SSL Certificate
##
echo "Installing Let's Encrypt SSL Certificate"
if ! sudo test -f "/etc/letsencrypt/live/${CONFIG[SERVER]}/fullchain.pem"; then 
    sudo certbot certonly -n --nginx --agree-tos -d ${CONFIG[SERVER]} -m it.system@tdh.ch --cert-name ${CONFIG[SERVER]} > /dev/null
fi

if [ $? == 0 ];then
    echo "# Certificate installed and configured by automated script" > tmp_${CONFIG[NAME]}.conf
    echo "ssl_certificate /etc/letsencrypt/live/${CONFIG[SERVER]}/fullchain.pem;" >> tmp_${CONFIG[NAME]}.conf
    echo "ssl_certificate_key /etc/letsencrypt/live/${CONFIG[SERVER]}/privkey.pem;" >> tmp_${CONFIG[NAME]}.conf
    sudo mv -f tmp_${CONFIG[NAME]}.conf /etc/nginx/snippets/${CONFIG[NAME]}.conf
else
    echo "Warning: something was wrong with certbot, site will use selfsigned certificates"
fi

## Checking configuration after getting Let's Encrypt certificate
RESULT=$(sudo nginx -t)
## if something is wrong with NGINX conf rollback all previous operations
if [ $? != 0 ];then
    echo "Error: NGINX configuration file error."
    ./clean.sh $1
    unset CONFIG
    unset RESULT
    exit 1
fi
## Everything seems be Ok with NGINX reloading configuration
sudo systemctl reload nginx.service

##
## Creating site folder
##
sudo mkdir -p /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}
sudo chown -fR www-data:www-data /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}
sudo chmod -R g+wx /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}
echo "<?php print \"Site ${CONFIG[NAME]} is configured...\"; ?>" | sudo tee /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/index.php >/dev/null

##
## If APPLICATION is defined launching configuration script
##
if [ "${CONFIG[APPLICATION]}" != "" ] && test -f "./${CONFIG[APPLICATION]}.sh"; then
    echo "Launching ${CONFIG[APPLICATION]} application configuration..."
    source ./${CONFIG[APPLICATION]}.sh $CONF_FILE
else
    echo "<?php print \"Site ${CONFIG[NAME]} is running...\"; ?>" | sudo tee /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/index.php >/dev/null
    echo "No application defined, or no existing configuration script."
fi
if [ $? == 0 ];then echo "Site ${CONFIG[NAME]} is successfully configured"; fi

###
### End of script
###
unset CONFIG
unset RESULT
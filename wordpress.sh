#!/bin/bash
#
# Wordpress install script (normaly launched by new.sh)
#
## Loading config
if [ "${CONFIG[NAME]}" == "" ]; then source ./loadconfig.sh; fi

echo "Starting Wordpress installation for ${CONFIG[NAME]}..."

# Downloading latest version of wordpress
curl -O https://wordpress.org/latest.tar.gz
# unzip wordpress
tar -zxf latest.tar.gz
# Moving application to site folder
sudo mv -f wordpress/* /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/

# Configuring wordpress
sudo cp /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config-sample.php /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config.php

sudo perl -pi -e "s/database_name_here/${CONFIG[DB_NAME]}/g" /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config.php
sudo perl -pi -e "s/username_here/${CONFIG[DB_USER]}/g" /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config.php
sudo perl -pi -e "s/password_here/${CONFIG[DB_PASSWORD]}/g" /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config.php

#set WP salts
sudo perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-config.php

# Creating uploads folder
sudo mkdir /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-content/uploads
sudo chmod 775 /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}/wp-content/uploads

# Configuring file and folder permission to nginx user (www-data)
sudo chown -fR www-data:www-data /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}
sudo chmod -R ug+wx /${CONFIG[SITES_ROOT]}/${CONFIG[NAME]}

# removing working files
rm  latest.tar.gz
rm -fR  wordpress


echo "Wordpress succesfully configured..."

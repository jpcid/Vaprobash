#!/usr/bin/env bash

echo ">>> Installing Cartalyst Platform"

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [ -z "$2" ]; then
    cartalyst_platform_root_folder="/vagrant/platform"
else
    cartalyst_platform_root_folder="$2"
fi

# Test if Composer is installed
composer --version > /dev/null 2>&1
COMPOSER_IS_INSTALLED=$?

if [ $COMPOSER_IS_INSTALLED -gt 0 ]; then
    echo "ERROR: Laravel install requires composer"
    exit 1
fi

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# Test if Apache or Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Create Laravel folder if needed
if [ ! -d $cartalyst_platform_root_folder ]; then
    mkdir -p $cartalyst_platform_root_folder
fi

if [ ! -f "$cartalyst_platform_root_folder/composer.json" ]; then
    # Create Cartalyst Platform

    git clone https://github.com/cartalyst/platform.git $cartalyst_platform_root_folder
    sudo chown -R vagrant:vagrant $cartalyst_platform_root_folder
    composer install

else
    # Go to vagrant folder
    cd $cartalyst_platform_root_folder

    # Install Laravel
    if [ $HHVM_IS_INSTALLED -eq 0 ]; then
        hhvm /usr/local/bin/composer install --prefer-dist
    else
        composer install --prefer-dist
    fi

    # Go to the previous folder
    cd -
fi

if [ $NGINX_IS_INSTALLED -eq 0 ]; then
    nginx_root=$(echo "$cartalyst_platform_root_folder/public" | sed 's/\//\\\//g')

    # Change default vhost created
    sed -i "s/root \/vagrant/root $nginx_root/" /etc/nginx/sites-available/vagrant
    sudo service nginx reload
fi

if [ $APACHE_IS_INSTALLED -eq 0 ]; then
    # Remove apache vhost from default and create a new one
    rm /etc/apache2/sites-enabled/$1.xip.io.conf > /dev/null 2>&1
    rm /etc/apache2/sites-available/$1.xip.io.conf > /dev/null 2>&1
    vhost -s $1.xip.io -d "$cartalyst_platform_root_folder/public"
    sudo service apache2 reload
fi

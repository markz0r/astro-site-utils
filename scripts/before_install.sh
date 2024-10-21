#!/bin/bash
set -e
REQUIRED_PACKAGES="httpd mod_ssl mod_lua augeas-libs"

# Update package list and upgrade all packages
yum update -y

# Install required packages
yum install -y $REQUIRED_PACKAGES

# Certbot gets installed with pip to /opt/certbot
# Try to activate virtualenv in /opt/certbot
if [ -f /opt/certbot/bin/activate ]; then
    source /opt/certbot/bin/activate
    # update pip and certbot
    pip install --upgrade pip
    pip install --upgrade certbot
    # deactivate virtualenv
    deactivate
    echo "Certbot is already installed in /opt/certbot, updated to the latest version."
else
    echo "Certbot is not installed in /opt/certbot, installing..."
    # Install certbot
    sudo python3 -m venv /opt/certbot/
    source /opt/certbot/bin/activate
    pip install --upgrade pip
    pip install certbot
    pip install certbot-apache
    deactivate
    echo "Certbot now installed in /opt/certbot."
fi

# Clear the /var/www/<<DESTINATION_S3>> directory
rm -rf /var/www/<<DESTINATION_S3>>
#!/bin/bash
set -e
rootDirectory="/opt/codedeploy-agent/deployment-root" # note: this will be different if you
VHOST_CONF_PATH="$rootDirectory/$DEPLOYMENT_GROUP_ID/$DEPLOYMENT_ID/deployment-archive/scripts/<<DESTINATION_S3>>.conf"
CERT_BOT_RUNNER_PATH="$rootDirectory/$DEPLOYMENT_GROUP_ID/$DEPLOYMENT_ID/deployment-archive/scripts/certbot-runner.sh"

chown -R apache:apache /var/www/<<DESTINATION_S3>>

# update selinux context
restorecon -R /var/www/<<DESTINATION_S3>>

# function for updating httpd configuration, restarting httpd and deploying certificates
deploy_vhost() {
    cp ${VHOST_CONF_PATH} /etc/httpd/conf.d/
    cp ${CERT_BOT_RUNNER_PATH} /etc/httpd/conf.d/
    chmod +x /etc/httpd/conf.d/certbot-runner.sh
    /etc/httpd/conf.d/certbot-runner.sh
    systemctl restart httpd
}

# check if /etc/httpd/conf.d/<<DESTINATION_S3>>.conf exists
if [ ! -f /etc/httpd/conf.d/<<DESTINATION_S3>>.conf ]; then
    deploy_vhost
    exit 0
else
    echo "httpd configuration file already exists, checking for changes..."
    diff $VHOST_CONF_PATH /etc/httpd/conf.d/<<DESTINATION_S3>>.conf || deploy_vhost
fi
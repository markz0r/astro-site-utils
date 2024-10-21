#!/bin/bash
set -e

# Rename the vhost file to disable it if it exists
# if [ -f /etc/httpd/conf.d/<<DESTINATION_S3>>.conf ]; then
#     mv /etc/httpd/conf.d/<<DESTINATION_S3>>.conf /etc/httpd/conf.d/<<DESTINATION_S3>>.conf.disabled
#     systemctl restart httpd
# else
#     echo "Vhost file not found, nothing to do."
# fi
echo "not doing anything"
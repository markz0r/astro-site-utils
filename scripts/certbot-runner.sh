#!/bin/bash

deploy_certs_with_certbot() {
    # Define the directory and exclusion patterns
    VHOST_DIR="/etc/httpd/conf.d/"
    EXCLUDED_VHOSTS_CONFS=("autoindex.conf" "ssl.conf" "welcome.conf" "userdir.conf" "php.conf" "*-le-ssl.conf")
    EXLUDED_DOMAINS=("localhost" "mchost")

    # List all .conf files in the directory
    VHOST_CONFS=$(find "$VHOST_DIR" -type f -name "*.conf")

    # Function to check if a file matches any of the exclusion patterns
    matches_exclusion() {
        local file=$1
        for pattern in "${EXCLUDED_VHOSTS_CONFS[@]}"; do
            if [[ $file == $VHOST_DIR$pattern ]]; then
                return 0
            fi
        done
        return 1
    }

    # Filter the list of files
    FILTERED_VHOST_CONFS=()
    for file in $VHOST_CONFS; do
        if ! matches_exclusion "$file"; then
            FILTERED_VHOST_CONFS+=("$file")
        fi
    done
    # Print the filtered list of files
    echo "#################################################"
    echo "Filtered vhost confs:"
    for file in "${FILTERED_VHOST_CONFS[@]}"; do
        echo "  $file"
    done
    echo "#################################################"

    # Loop over the specified files getting the ServerName and ServerAlias directives only from the included vhosts and vhosts listening on port 80 which could be Listen 80 or <VirtualHost *:80>
    for file in "${FILTERED_VHOST_CONFS[@]}"; do
        domain_args=""
        echo "#################################################"
        echo "Processing file: $file"
        if grep -qE "^\s*(ServerName|ServerAlias)\s" "$file" && grep -qE "^\s*(Listen\s+80|<VirtualHost\s+\*:80>)" "$file"; then
            domain_args+="$(grep -E "^\s*(ServerName|ServerAlias)\s" "$file" | sed -E 's/^\s*(ServerName|ServerAlias)\s+//')"
        fi
        domain_args=$(echo "$domain_args" | tr '\n' ',' | sed 's/,$//')
        new_domains=""
        existing_domains=$(sudo /opt/certbot/bin/certbot certificates | grep -oP '(?<=Domains: ).*')
        # Only renew the certificate if there are domains to renew or new domains to add
        for domain in $(echo $domain_args | tr "," "\n"); do
            if [[ ! $existing_domains =~ $domain ]] && [[ ! " ${EXLUDED_DOMAINS[@]} " =~ " ${domain} " ]]; then
                new_domains="$new_domains$domain,"
            fi
        done
        if [[ -z $new_domains ]]; then
            echo "No domains to add."
        else
            # Remove the trailing comma
            new_domains=$(echo $new_domains | sed 's/,$//')
            echo "New domains: $new_domains"
            sudo /opt/certbot/bin/certbot --apache -n --expand -d $domain_args
            sudo systemctl restart httpd
        fi
        echo "Done processing file: $file"
        echo "#################################################"
    done

    # Join the domain arguments into a single, comma-separated string

}

# Check if dry run argument is provided
if [[ $1 == "--dry-run" ]]; then
    echo "Dry run. The following command would be executed:"
    echo "sudo /opt/certbot/bin/certbot --apache -d $domain_args"
elif [[ $1 == "--renew" ]]; then
    # Run Certbot in renew mode
    sudo /opt/certbot/bin/certbot renew
else
    # Run Certbot
    deploy_certs_with_certbot
fi

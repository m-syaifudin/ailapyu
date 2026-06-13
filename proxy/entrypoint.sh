#!/bin/sh

set -e

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

# Start nginx with HTTP config
cp /etc/nginx/conf.d/http.conf /etc/nginx/conf.d/default.conf

nginx

# Obtain certificate if missing
if [ ! -f "$CERT_PATH" ]; then
    echo "Obtaining Let's Encrypt certificate..."

    certbot certonly \
        --webroot \
        -w /var/www/certbot \
        -d "${DOMAIN}" \
        -d "www.${DOMAIN}" \
        --email "${EMAIL}" \
        --agree-tos \
        --non-interactive \
        --no-eff-email

    echo "Certificate generated."
fi

# Enable HTTPS config
envsubst '${DOMAIN}' \
< /etc/nginx/conf.d/https.conf.template \
> /etc/nginx/conf.d/default.conf

nginx -s reload

# Renewal loop
while true
do
    certbot renew --quiet

    nginx -s reload

    sleep 12h
done
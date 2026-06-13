FROM nginx:alpine

RUN apk add --no-cache certbot openssl bash gettext

COPY nginx.conf                        /etc/nginx/nginx.conf
COPY conf.d/http.conf                  /etc/nginx/conf.d/http.conf
COPY conf.d/https.conf.template        /etc/nginx/conf.d/https.conf.template

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
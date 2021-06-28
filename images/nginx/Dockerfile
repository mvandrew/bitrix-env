FROM nginx:latest

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ENV SITE_DOMAIN="mydomain.com"

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    openssl \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN openssl req -x509 -nodes -days 365 -subj "/C=CA/ST=QC/O=Company, Inc./CN=${SITE_DOMAIN}" -addext "subjectAltName=DNS:${SITE_DOMAIN}" \
    -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt;

RUN echo ${SITE_DOMAIN} > /etc/hostname

ADD conf/nginx.conf /etc/nginx/
ADD conf/default.conf /etc/nginx/conf.d/
ADD conf/upstream.conf /etc/nginx/conf.d/

ADD entrypoint.sh /usr/bin

RUN usermod -u 1000 www-data && \
    chmod 775 /usr/bin/entrypoint.sh

#CMD ["nginx"]
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]

EXPOSE 80 443

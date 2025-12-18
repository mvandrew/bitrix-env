# ===========================================
# Bitrix PHP 8.1 Apache Docker Image
# ===========================================
FROM php:8.1-apache

LABEL maintainer="Andrey Mishchenko <info@msav.ru>"
LABEL description="PHP 8.1 Apache image optimized for 1C-Bitrix CMS"

ARG DEBIAN_FRONTEND=noninteractive

# ===========================================
# Environment Variables (backward compatible)
# ===========================================
ENV BX_TIMEZONE="Europe/Moscow"
ENV TZ="Europe/Moscow"
ENV MEMORY_LIMIT="2048M"
ENV PHP_INI_TYPE="development"
ENV PHP_EX_OPCACHE_ENABLED="1"
ENV USER_ID="1000"
ENV GROUP_ID="1000"
ENV ENABLE_SSL="0"
ENV SITE_DOMAIN="mydomain.ru"
ENV SITE_IP="127.0.0.1"
ENV PROXY_IPS="127.0.0.1 127.0.0.2"
ENV MBSTRING_FUNC_OVERLOAD="0"
ENV SMTP_HOST="mailhog"
ENV SMTP_PORT="1025"
ENV SMTP_EMAIL="noreply@localhost"
ENV SMTP_PASSWORD=""

# ===========================================
# Install System Dependencies
# ===========================================
RUN set -eux \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        # Build tools
        pkg-config \
        build-essential \
        autoconf \
        bison \
        ca-certificates \
        curl \
        dpkg-dev \
        file \
        flex \
        g++ \
        gcc \
        git \
        make \
        patch \
        re2c \
        wget \
        xz-utils \
        # Libraries for PHP extensions
        libmcrypt-dev \
        zlib1g-dev \
        libmemcached-dev \
        libmagickwand-dev \
        libzip-dev \
        libwebp-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxpm-dev \
        libfreetype6-dev \
        libtidy-dev \
        libbz2-dev \
        libxslt-dev \
        libonig-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libpspell-dev \
        libldap2-dev \
        librabbitmq-dev \
        libzstd-dev \
        liblz4-dev \
        liblzf-dev \
        librdkafka-dev \
        libkrb5-dev \
        librrd-dev \
        libc-client-dev \
        # Locale and timezone
        locales \
        tzdata \
        # SSL
        ssl-cert \
        # Apache modules
        libapache2-mod-rpaf \
        # Mail
        msmtp \
    && pecl channel-update pecl.php.net \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# ===========================================
# Install PHP Extensions
# ===========================================

# bz2
RUN docker-php-ext-install -j$(nproc) bz2

# calendar
RUN docker-php-ext-install -j$(nproc) calendar

# exif
RUN docker-php-ext-install -j$(nproc) exif

# gd (with webp, jpeg, xpm, freetype)
RUN set -eux \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libXpm.* /usr/lib/ \
    && docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-xpm --with-freetype \
    && docker-php-ext-install -j$(nproc) gd

# gettext
RUN docker-php-ext-install -j$(nproc) gettext

# imap (with kerberos and ssl)
RUN set -eux \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libkrb5* /usr/lib/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl --with-imap \
    && docker-php-ext-install -j$(nproc) imap

# ldap
RUN set -eux \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libldap* /usr/lib/ \
    && docker-php-ext-configure ldap --with-ldap --with-ldap-sasl \
    && docker-php-ext-install -j$(nproc) ldap

# mysqli
RUN docker-php-ext-install -j$(nproc) mysqli

# opcache
RUN docker-php-ext-install -j$(nproc) opcache

# pdo_mysql
RUN docker-php-ext-configure pdo_mysql --with-zlib-dir=/usr \
    && docker-php-ext-install -j$(nproc) pdo_mysql

# pspell
RUN docker-php-ext-install -j$(nproc) pspell

# shmop
RUN docker-php-ext-install -j$(nproc) shmop

# sockets
RUN docker-php-ext-install -j$(nproc) sockets

# zip
RUN docker-php-ext-configure zip --with-zip \
    && docker-php-ext-install -j$(nproc) zip

# ===========================================
# Install PECL Extensions
# ===========================================

# amqp (RabbitMQ)
RUN echo "/usr" | pecl install amqp \
    && docker-php-ext-enable amqp

# igbinary (serialization)
RUN pecl install igbinary \
    && docker-php-ext-enable igbinary

# imagick
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && sed -i'' 's|.*"thread".*|  <policy domain="resource" name="thread" value="1"/>|g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS2".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS3".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"EPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PDF".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"XPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="delegate".*pattern="gs".*||g' /etc/ImageMagick-6/policy.xml

# mcrypt (legacy)
RUN pecl install mcrypt \
    && docker-php-ext-enable mcrypt

# memcache
RUN pecl install memcache \
    && docker-php-ext-enable memcache

# msgpack (serialization)
RUN pecl install msgpack \
    && docker-php-ext-enable msgpack

# memcached (with igbinary and msgpack)
RUN printf "\n\n\nyes\nyes\nyes\n" | pecl install memcached \
    && docker-php-ext-enable memcached

# lzf (compression)
RUN pecl install lzf \
    && docker-php-ext-enable lzf

# rdkafka (Kafka)
RUN pecl install rdkafka \
    && docker-php-ext-enable rdkafka

# rrd (RRDtool)
RUN pecl install rrd \
    && docker-php-ext-enable rrd

# xlswriter (Excel)
RUN pecl install xlswriter \
    && docker-php-ext-enable xlswriter

# ===========================================
# Install GIT Extensions (from source)
# ===========================================

# lz4 compression
RUN set -eux \
    && git clone https://github.com/kjdev/php-ext-lz4 /tmp/lz4 \
    && cd /tmp/lz4 \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && phpize \
    && ./configure --enable-lz4 --with-lz4-includedir=/usr \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable lz4 \
    && rm -rf /tmp/lz4

# zstd compression
RUN set -eux \
    && git clone https://github.com/kjdev/php-ext-zstd /tmp/zstd \
    && cd /tmp/zstd \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && phpize \
    && ./configure --enable-zstd --with-libzstd \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable zstd \
    && rm -rf /tmp/zstd

# redis (with igbinary, lz4, lzf, msgpack, zstd)
RUN set -eux \
    && if [ -f /usr/include/liblzf/lzf.h ]; then ln -s /usr/include/liblzf/lzf.h /usr/include/; fi \
    && git clone https://github.com/phpredis/phpredis /tmp/redis \
    && cd /tmp/redis \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && REDIS_ARGS=""; \
    if php -m | grep -q "igbinary"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-igbinary"; fi; \
    if php -m | grep -q "lz4"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-lz4 --with-liblz4=/usr"; fi; \
    if php -m | grep -q "lzf"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-lzf --with-liblzf=/usr"; fi; \
    if php -m | grep -q "msgpack"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-msgpack"; fi; \
    if php -m | grep -q "zstd"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-zstd"; fi; \
    phpize \
    && ./configure --enable-redis ${REDIS_ARGS} \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/redis

# ===========================================
# Install PEAR Extensions
# ===========================================
RUN pear install DB

# ===========================================
# Add Russian Trusted Certificates
# ===========================================
RUN mkdir -p /usr/local/share/ca-certificates/extra
COPY base/ssl/russia/russian_trusted_root_ca_pem.crt /usr/local/share/ca-certificates/extra/
COPY base/ssl/russia/russian_trusted_sub_ca_pem.crt /usr/local/share/ca-certificates/extra/
RUN update-ca-certificates

# ===========================================
# Generate SSL Certificate
# ===========================================
RUN make-ssl-cert generate-default-snakeoil

# ===========================================
# Configure Timezone
# ===========================================
RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# ===========================================
# Copy Configuration Files
# ===========================================
# Note: Build context should be the php-apache/ directory
# Use: docker build -f 8.1/Dockerfile .

# PHP configuration
COPY base/conf/php-dev.ini /usr/local/etc/php/conf.d/zzz-bitrix-php-dev.ini
COPY base/conf/php-prod.ini /usr/local/etc/php/conf.d/zzz-bitrix-php-prod.ini
COPY base/conf/opcache-dev.ini /usr/local/etc/php/conf.d/zzz-opcache-dev.ini
COPY base/conf/opcache-prod.ini /usr/local/etc/php/conf.d/zzz-opcache-prod.ini

# Apache configuration
COPY base/conf/apache/00-httpd.conf /etc/apache2/conf-available/00-bitrix-httpd.conf
COPY base/conf/apache/bitrix.conf /etc/apache2/sites-available/bitrix.conf
COPY base/conf/apache/bitrix-ssl.conf /etc/apache2/sites-available/bitrix-ssl.conf

# SMTP configuration
COPY base/conf/msmtprc.template /etc/msmtprc

# Health check
COPY base/scripts/health.php /usr/local/share/bitrix/health.php

# Entrypoint
COPY base/scripts/entrypoint.sh /usr/local/bin/bitrix-entrypoint.sh
RUN chmod +x /usr/local/bin/bitrix-entrypoint.sh

# ===========================================
# Configure Apache
# ===========================================
RUN a2enmod rewrite proxy headers include remoteip ssl expires rpaf \
    && a2enconf 00-bitrix-httpd \
    && a2dissite 000-default.conf \
    && a2dissite default-ssl.conf \
    && a2ensite bitrix.conf \
    && sed -i 's/^#\s*RPAFheader/    RPAFheader/' /etc/apache2/mods-available/rpaf.conf

# ===========================================
# Create Directories
# ===========================================
RUN mkdir -p /var/www/session /var/www/html /var/log/php /usr/local/share/bitrix \
    && chown -R www-data:www-data /var/www /var/log/php

# ===========================================
# Verify Extensions
# ===========================================
RUN set -eux \
    && php -v | grep -oE 'PHP\s[.0-9]+' | grep -oE '[.0-9]+' | grep '^8.1' \
    && php -m | grep -oiE '^Zend OPcache$' \
    && php -m | grep -oiE '^bz2$' \
    && php -m | grep -oiE '^calendar$' \
    && php -m | grep -oiE '^ctype$' \
    && php -m | grep -oiE '^curl$' \
    && php -m | grep -oiE '^dom$' \
    && php -m | grep -oiE '^exif$' \
    && php -m | grep -oiE '^fileinfo$' \
    && php -m | grep -oiE '^ftp$' \
    && php -m | grep -oiE '^gd$' \
    && php -m | grep -oiE '^gettext$' \
    && php -m | grep -oiE '^iconv$' \
    && php -m | grep -oiE '^json$' \
    && php -m | grep -oiE '^ldap$' \
    && php -m | grep -oiE '^mbstring$' \
    && php -m | grep -oiE '^mysqlnd$' \
    && php -m | grep -oiE '^mysqli$' \
    && php -m | grep -oiE '^pspell$' \
    && php -m | grep -oiE '^shmop$' \
    && php -m | grep -oiE '^simplexml$' \
    && php -m | grep -oiE '^sockets$' \
    && php -m | grep -oiE '^sodium$' \
    && php -m | grep -oiE '^tokenizer$' \
    && php -m | grep -oiE '^xml$' \
    && php -m | grep -oiE '^xmlreader$' \
    && php -m | grep -oiE '^xmlwriter$' \
    && php -m | grep -oiE '^mcrypt$' \
    && php -m | grep -oiE '^zip$' \
    && php -m | grep -oiE '^memcache$' \
    && php -m | grep -oiE '^memcached$' \
    && php -m | grep -oiE '^redis$' \
    && php -m | grep -oiE '^imagick$' \
    && php -m | grep -oiE '^rrd$' \
    && php -m | grep -oiE '^imap$' \
    && php -m | grep -oiE '^xlswriter$' \
    && php -m | grep -oiE '^amqp$' \
    && php -m | grep -oiE '^igbinary$' \
    && php -m | grep -oiE '^msgpack$' \
    && php -m | grep -oiE '^lz4$' \
    && php -m | grep -oiE '^zstd$' \
    && php -m | grep -oiE '^lzf$' \
    && php -m | grep -oiE '^rdkafka$' \
    && pear list | grep -oiE '^DB\s' \
    && echo "All extensions verified successfully!"

# ===========================================
# Final Setup
# ===========================================
VOLUME ["/var/www/html", "/var/www/session"]
WORKDIR /var/www/html
EXPOSE 80 443

ENTRYPOINT ["bitrix-entrypoint.sh"]
STOPSIGNAL SIGWINCH
CMD ["apache2-foreground"]

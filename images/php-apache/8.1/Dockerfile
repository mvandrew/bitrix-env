# ===========================================
# Bitrix PHP 8.1 Apache Docker Image (Optimized)
# ===========================================
# Multi-stage build to reduce final image size
# Build tools and -dev packages are only in builder stage
#
# Note: Using bookworm explicitly because Trixie removed libc-client-dev
# which is required for IMAP extension

# ===========================================
# Stage 1: BUILDER - Compile all extensions
# ===========================================
FROM php:8.1-apache-bookworm AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install ALL build dependencies in one layer
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
        # Libraries for PHP extensions (-dev packages)
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
    && pecl channel-update pecl.php.net \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks for architecture-specific libraries
RUN set -eux \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libXpm.* /usr/lib/ \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libkrb5* /usr/lib/ \
    && ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libldap* /usr/lib/

# Configure and install built-in extensions (consolidated)
RUN set -eux \
    && docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-xpm --with-freetype \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl --with-imap \
    && docker-php-ext-configure ldap --with-ldap --with-ldap-sasl \
    && docker-php-ext-configure pdo_mysql --with-zlib-dir=/usr \
    && docker-php-ext-configure zip --with-zip \
    && docker-php-ext-install -j$(nproc) \
        bz2 \
        calendar \
        exif \
        gd \
        gettext \
        imap \
        ldap \
        mysqli \
        opcache \
        pdo_mysql \
        pspell \
        shmop \
        sockets \
        zip

# Install PECL extensions - serialization first (needed by memcached/redis)
RUN set -eux \
    && pecl install igbinary \
    && pecl install msgpack \
    && docker-php-ext-enable igbinary msgpack

# Install remaining PECL extensions (consolidated)
RUN set -eux \
    && echo "/usr" | pecl install amqp \
    && pecl install imagick \
    && pecl install mcrypt \
    && pecl install memcache \
    && printf "\n\n\nyes\nyes\nyes\n" | pecl install memcached \
    && pecl install lzf \
    && pecl install rdkafka \
    && pecl install rrd \
    && pecl install xlswriter \
    && docker-php-ext-enable amqp imagick mcrypt memcache memcached lzf rdkafka rrd xlswriter

# Build extensions from Git (lz4, zstd, redis)
# Note: Using separate RUN commands to avoid TLS issues with large git operations
RUN set -ex \
    && git clone https://github.com/kjdev/php-ext-lz4 /tmp/lz4 \
    && cd /tmp/lz4 \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && phpize \
    && ./configure --enable-lz4 --with-lz4-includedir=/usr \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable lz4 \
    && rm -rf /tmp/lz4

RUN set -ex \
    && git clone https://github.com/kjdev/php-ext-zstd /tmp/zstd \
    && cd /tmp/zstd \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && phpize \
    && ./configure --enable-zstd --with-libzstd \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable zstd \
    && rm -rf /tmp/zstd

RUN set -ex \
    && if [ -f /usr/include/liblzf/lzf.h ]; then ln -s /usr/include/liblzf/lzf.h /usr/include/; fi \
    && git clone https://github.com/phpredis/phpredis /tmp/redis \
    && cd /tmp/redis \
    && git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
    && REDIS_ARGS="" \
    && if php -m | grep -q "igbinary"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-igbinary"; fi \
    && if php -m | grep -q "lz4"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-lz4 --with-liblz4=/usr"; fi \
    && if php -m | grep -q "lzf"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-lzf --with-liblzf=/usr"; fi \
    && if php -m | grep -q "msgpack"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-msgpack"; fi \
    && if php -m | grep -q "zstd"; then REDIS_ARGS="${REDIS_ARGS} --enable-redis-zstd"; fi \
    && phpize \
    && ./configure --enable-redis ${REDIS_ARGS} \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/redis

# Install PEAR DB
RUN pear install DB

# ===========================================
# Stage 2: RUNTIME - Final optimized image
# ===========================================
FROM php:8.1-apache-bookworm AS runtime

LABEL maintainer="Andrey Mishchenko <info@msav.ru>"
LABEL description="PHP 8.1 Apache image optimized for 1C-Bitrix CMS (multi-stage build)"

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
# Install ONLY Runtime Dependencies
# ===========================================
RUN set -eux \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        # Runtime libraries for PHP extensions (NOT -dev packages!)
        # ImageMagick
        libmagickwand-6.q16-6 \
        libmagickcore-6.q16-6 \
        # Memcached
        libmemcached11 \
        libmemcachedutil2 \
        # AMQP (RabbitMQ)
        librabbitmq4 \
        # Kafka
        librdkafka1 \
        # RRDtool
        librrd8 \
        # IMAP
        libc-client2007e \
        libkrb5-3 \
        libgssapi-krb5-2 \
        # Mcrypt
        libmcrypt4 \
        # Compression
        liblz4-1 \
        libzstd1 \
        liblzf1 \
        # LDAP
        libldap-2.5-0 \
        # GD dependencies
        libwebp7 \
        libjpeg62-turbo \
        libpng16-16 \
        libxpm4 \
        libfreetype6 \
        # Other
        libbz2-1.0 \
        libaspell15 \
        libzip4 \
        libonig5 \
        # Utilities needed at runtime
        locales \
        tzdata \
        ssl-cert \
        ca-certificates \
        wget \
        libapache2-mod-rpaf \
        msmtp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# ===========================================
# Copy compiled extensions from builder
# ===========================================
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy PEAR packages (DB.php and DB/ from /usr/local/lib/php)
COPY --from=builder /usr/local/lib/php/DB.php /usr/local/lib/php/DB.php
COPY --from=builder /usr/local/lib/php/DB/ /usr/local/lib/php/DB/

# ===========================================
# Configure ImageMagick policy
# ===========================================
RUN set -eux \
    && sed -i'' 's|.*"thread".*|  <policy domain="resource" name="thread" value="1"/>|g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS2".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS3".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"EPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PDF".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"XPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="delegate".*pattern="gs".*||g' /etc/ImageMagick-6/policy.xml

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
# PHP configuration
COPY base/conf/php-dev.ini /usr/local/etc/php/conf.d/zzz-bitrix-php-dev.ini
COPY base/conf/php-prod.ini /usr/local/etc/php/conf.d/zzz-bitrix-php-prod.ini
COPY base/conf/opcache-dev.ini /usr/local/share/bitrix/opcache-dev.ini
COPY base/conf/opcache-prod.ini /usr/local/share/bitrix/opcache-prod.ini

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
    && test -f /usr/local/lib/php/DB.php \
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

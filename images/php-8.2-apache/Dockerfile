FROM php:8.2-apache

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG DEBIAN_FRONTEND=noninteractive

ARG BX_TIMEZONE="Europe/Moscow"
ENV BX_TIMEZONE ${BX_TIMEZONE}

ARG MEMORY_LIMIT=2048M
ENV MEMORY_LIMIT ${MEMORY_LIMIT}

ARG PHP_CONFIG_FILE="/usr/local/etc/php/conf.d/zzz-bitrix-php.ini"
ENV PHP_CONFIG_FILE ${PHP_CONFIG_FILE}

ARG PHP_CONFIG_FILE_EX="/usr/local/etc/php/conf.d/zzzz-bitrix-php-ex.ini"
ENV PHP_CONFIG_FILE_EX ${PHP_CONFIG_FILE_EX}

ENV PHP_EX_OPCACHE_ENABLED=1

ARG USER_ID=1000
ENV USER_ID ${USER_ID}

ARG GROUP_ID=1000
ENV GROUP_ID ${GROUP_ID}

ARG ENABLE_SSL=0
ENV ENABLE_SSL ${ENABLE_SSL}

ARG SITE_DOMAIN="mydomain.ru"
ENV SITE_DOMAIN ${SITE_DOMAIN}

ARG SITE_IP="127.0.0.1"
ENV SITE_IP ${SITE_IP}

ARG PROXY_IPS="127.0.0.1 127.0.0.2"
ENV PROXY_IPS ${PROXY_IPS}

ARG MBSTRING_FUNC_OVERLOAD="2"
ENV MBSTRING_FUNC_OVERLOAD ${MBSTRING_FUNC_OVERLOAD}

# Параметры подключения к почтовому ящику
ARG SMTP_HOST="smtp.yandex.ru"
ENV SMTP_HOST ${SMTP_HOST}
ARG SMTP_PORT="587"
ENV SMTP_PORT ${SMTP_PORT}
ARG SMTP_EMAIL="my@email.ru"
ENV SMTP_EMAIL ${SMTP_EMAIL}
ARG SMTP_PASSWORD="password"
ENV SMTP_PASSWORD ${SMTP_PASSWORD}
ARG SMTP_AUTHENTICATION
ARG SMTP_AUTHENTICATION_METHOD
ARG SMTP_ENABLE_TLS

# https://github.com/devilbox/docker-php-fpm/blob/master/Dockerfiles/mods/Dockerfile-7.4

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
        pkg-config \
        build-essential \
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
        libpng-dev \
        libgeoip-dev \
        libtidy-dev \
        libbz2-dev \
        libxslt-dev \
        locales \
        tzdata \
        ssl-cert \
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
        libgeoip-dev \
        libkrb5-dev \
        librrd-dev \
        wget \
        libapache2-mod-rpaf \
# Build tools
        autoconf \
        bison \
        bisonc++ \
        ca-certificates \
        curl \
        dpkg-dev \
        file \
        flex \
        g++ \
        gcc \
        git \
        lemon \
        libc-client-dev \
        libc-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        make \
        patch \
        pkg-config \
        re2c \
        xz-utils \
# Mail \
        msmtp \
    && pecl channel-update pecl.php.net \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
    && true

# -------------------- Installing PHP Extension: amqp --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Custom:       Pecl command
	&& echo "/usr" | pecl install amqp \
	# Enabling
	&& docker-php-ext-enable amqp \
	&& true

# -------------------- Installing PHP Extension: bz2 --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) bz2 \
	&& true

# -------------------- Installing PHP Extension: calendar --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) calendar \
	&& true

# -------------------- Installing PHP Extension: exif --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) exif \
	&& true

# -------------------- Installing PHP Extension: gd --------------------
RUN set -eux \
	# Generic pre-command
	&& ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libXpm.* /usr/lib/ \
	# Installation: Version specific
	# Type:         Built-in extension
	# Custom:       configure command
	&& docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-xpm --with-freetype \
    && docker-php-ext-configure ftp --with-openssl-dir=/usr \
	# Installation
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd \
    && docker-php-ext-install ftp \
	&& true

# -------------------- Installing PHP Extension: imagick --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install imagick \
	# Enabling
	&& docker-php-ext-enable imagick \
	# Generic post-command
	&& sed -i'' 's|.*"thread".*|  <policy domain="resource" name="thread" value="1"/>|g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS2".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS3".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"EPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PDF".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"XPS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="coder".*"PS".*||g' /etc/ImageMagick-6/policy.xml \
    && sed -i'' 's|.*<policy domain="delegate".*pattern="gs".*||g' /etc/ImageMagick-6/policy.xml \
    && true

# -------------------- Installing PHP Extension: imap --------------------
RUN set -eux \
	# Generic pre-command
	&& ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libkrb5* /usr/lib/ \
	# Installation: Generic
	# Type:         Built-in extension
	# Custom:       configure command
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl --with-imap \
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) imap \
	&& true

# -------------------- Installing PHP Extension: gettext --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gettext \
	&& true

# -------------------- Installing PHP Extension: ldap --------------------
RUN set -eux \
	# Generic pre-command
	&& ln -s /usr/lib/$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)/libldap* /usr/lib/ \
	# Installation: Generic
	# Type:         Built-in extension
	# Custom:       configure command
	&& docker-php-ext-configure ldap --with-ldap --with-ldap-sasl \
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) ldap \
	&& true

# -------------------- Installing PHP Extension: igbinary --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install igbinary \
	# Enabling
	&& docker-php-ext-enable igbinary \
	&& true

# -------------------- Installing PHP Extension: mcrypt --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install mcrypt \
	# Enabling
	&& docker-php-ext-enable mcrypt \
	&& true


# -------------------- Installing PHP Extension: memcache --------------------
RUN set -eux \
	# Installation: Version specific
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install memcache \
	# Enabling
	&& docker-php-ext-enable memcache \
	&& true

# -------------------- Installing PHP Extension: msgpack --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install msgpack \
	# Enabling
	&& docker-php-ext-enable msgpack \
	&& true

# -------------------- Installing PHP Extension: memcached --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Custom:       Pecl command
	&& printf "\n\n\nyes\nyes\nyes\n" | pecl install memcached \
	# Enabling
	&& docker-php-ext-enable memcached \
	&& true

# -------------------- Installing PHP Extension: mysqli --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) mysqli \
	&& true

# -------------------- Installing PHP Extension: pdo_mysql --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	# Custom:       configure command
	&& docker-php-ext-configure pdo_mysql --with-zlib-dir=/usr \
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) pdo_mysql \
	&& true

# -------------------- Installing PHP Extension: opcache --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) opcache \
	&& true

# -------------------- Installing PHP Extension: lz4 --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         GIT extension
	&& git clone https://github.com/kjdev/php-ext-lz4 /tmp/lz4 \
	&& cd /tmp/lz4 \
	# Custom:       Branch
	&& git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
	# Default:      Install command
	&& phpize \
	&& ./configure  --enable-lz4 --with-lz4-includedir=/usr \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	# Enabling
	&& docker-php-ext-enable lz4 \
	&& true

# -------------------- Installing PHP Extension: zstd --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         GIT extension
	&& git clone https://github.com/kjdev/php-ext-zstd /tmp/zstd \
	&& cd /tmp/zstd \
	# Custom:       Branch
	&& git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
	# Default:      Install command
	&& phpize \
	&& ./configure  --enable-zstd --with-libzstd \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	# Enabling
	&& docker-php-ext-enable zstd \
	&& true

# -------------------- Installing PHP Extension: lzf --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install lzf \
	# Enabling
	&& docker-php-ext-enable lzf \
	&& true

# -------------------- Installing PHP Extension: redis --------------------
RUN set -eux \
	# Generic pre-command
	&& if [ -f /usr/include/liblzf/lzf.h ]; then \
      ln -s /usr/include/liblzf/lzf.h /usr/include/; \
    fi \
	# Installation: Generic
	# Type:         GIT extension
	&& git clone https://github.com/phpredis/phpredis /tmp/redis \
	&& cd /tmp/redis \
	# Custom:       Branch
	&& git checkout $(git tag | grep -E '^[.0-9]+$' | sort -V | tail -1) \
	# Custom:       Install command
	&& REDIS_ARGS=""; \
    if php -m | grep -q "igbinary"; then \
      REDIS_ARGS="${REDIS_ARGS} --enable-redis-igbinary"; \
    fi; \
    if php -m | grep -q "lz4"; then \
      REDIS_ARGS="${REDIS_ARGS} --enable-redis-lz4 --with-liblz4=/usr"; \
    fi; \
    if php -m | grep -q "lzf"; then \
      REDIS_ARGS="${REDIS_ARGS} --enable-redis-lzf --with-liblzf=/usr"; \
    fi; \
    if php -m | grep -q "msgpack"; then \
      REDIS_ARGS="${REDIS_ARGS} --enable-redis-msgpack"; \
    fi; \
    if php -m | grep -q "zstd"; then \
      REDIS_ARGS="${REDIS_ARGS} --enable-redis-zstd"; \
    fi; \
    phpize \
    && ./configure --enable-redis ${REDIS_ARGS} \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
	# Enabling
	&& docker-php-ext-enable redis \
	&& true

# -------------------- Installing PHP Extension: pspell --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) pspell \
	&& true


# -------------------- Installing PHP Extension: rdkafka --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install rdkafka \
	# Enabling
	&& docker-php-ext-enable rdkafka \
	&& true

# -------------------- Installing PHP Extension: shmop --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) shmop \
	&& true

# -------------------- Installing PHP Extension: sockets --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) sockets \
	&& true

# -------------------- Installing PHP Extension: zip --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	# Custom:       configure command
	&& docker-php-ext-configure zip --with-zip \
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) zip \
	&& true

# -------------------- Installing PHP Extension: geoip --------------------
#RUN set -eux \
#	# Installation: Generic
#	# Type:         PECL extension
#	# Default:      Pecl command
#	&& pecl install geoip \
#	# Enabling
#	&& docker-php-ext-enable geoip \
#	&& true

# -------------------- Installing PHP Extension: rrd --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install rrd \
	# Enabling
	&& docker-php-ext-enable rrd \
	&& true

# -------------------- Installing PHP Extension: pear-DB --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PEAR extension
	&& pear install DB \
	&& true

# -------------------- Installing PHP Extension: xlswriter --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         PECL extension
	# Default:      Pecl command
	&& pecl install xlswriter \
	# Enabling
	&& docker-php-ext-enable xlswriter \
	&& true \

# Add russian trusted certs
RUN mkdir "/usr/local/share/ca-certificates/extra"
COPY "ssl/russia/russian_trusted_root_ca_pem.crt" "/usr/local/share/ca-certificates/extra/russian_trusted_root_ca_pem.crt"
COPY "ssl/russia/russian_trusted_sub_ca_pem.crt" "/usr/local/share/ca-certificates/extra/russian_trusted_sub_ca_pem.crt"
RUN update-ca-certificates

RUN make-ssl-cert generate-default-snakeoil

RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
COPY conf/php.ini ${PHP_CONFIG_FILE}

RUN usermod -u ${USER_ID} www-data \
    && groupmod -g ${GROUP_ID} www-data

RUN mkdir /var/www/session \
    && mkdir /var/www/common \
    && chown -R www-data:www-data /var/www

RUN a2enmod rewrite proxy headers include remoteip ssl expires rpaf

RUN sed -i 's/^#\s*RPAFheader/    RPAFheader/' /etc/apache2/mods-available/rpaf.conf
#    && sed -i 's/RPAFproxy_ips/# RPAFproxy_ips/' /etc/apache2/mods-available/rpaf.conf
#RUN sed -i 's/^#\s*RPAFheader\s*X-Real-IP/    RPAFheader X-Forwarded-For/' /etc/apache2/mods-available/rpaf.conf \
#    && sed -i 's/RPAFproxy_ips/# RPAFproxy_ips/' /etc/apache2/mods-available/rpaf.conf
#    && sed -i 's/RPAFsethostname\s*On/RPAFsethostname Off/' /etc/apache2/mods-available/rpaf.conf

RUN a2dissite 000-default.conf \
    && a2dissite default-ssl.conf

COPY sites-available/bitrix.conf /etc/apache2/sites-available
COPY sites-available/bitrix-ssl.conf /etc/apache2/sites-available
RUN a2ensite bitrix.conf
#    && a2ensite bitrix-ssl.conf

VOLUME ["/var/www/html", "/var/www/session"]

WORKDIR /var/www/html

##
## Проверка
##
RUN set -eux \
	&& php -v | grep -oE 'PHP\s[.0-9]+' | grep -oE '[.0-9]+' | grep '^8.2' \
    \
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
#    && php -m | grep -oiE '^geoip$' \
    && php -m | grep -oiE '^memcache$' \
    && php -m | grep -oiE '^rrd$' \
    && php -m | grep -oiE '^imap$' \
    && php -m | grep -oiE '^xlswriter$' \
    \
    && pear list | grep -oiE '^DB\s' \
    \
    && true

COPY conf/msmtprc /etc/msmtprc

# Дополнительная конфигурация Битрикс окружения
RUN mkdir "/etc/apache2/conf-bx" \
    && chown root:root -R "/etc/apache2/conf-bx" \
    && chmod 755 -R "/etc/apache2/conf-bx" \
    && echo "IncludeOptional conf-bx/*.conf" >> "/etc/apache2/apache2.conf"
COPY conf/apache2/conf-bx/* /etc/apache2/conf-bx

COPY bitrix-entrypoint.sh /usr/local/bin
ENTRYPOINT [ "bitrix-entrypoint.sh" ]
STOPSIGNAL SIGWINCH

EXPOSE 80 443
CMD [ "apache2-foreground" ]

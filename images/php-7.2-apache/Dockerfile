FROM php:7.2-apache

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

#RUN docker-php-ext-configure gd \
#    --with-jpeg \
#    --with-xpm \
#    --with-freetype

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    pkg-config \
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
    libonig-dev \
    wget \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) bz2 bcmath calendar gd pdo pdo_mysql iconv mbstring intl tidy xmlrpc mysqli xsl sockets xml soap \
    && pecl channel-update pecl.php.net \
    && pecl install mcrypt memcache memcached apcu imagick zip redis oauth \
    && docker-php-ext-enable mcrypt memcached apcu imagick zip redis oauth \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

FROM php:8.1-apache

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG DEBIAN_FRONTEND=noninteractive

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

# -------------------- Installing PHP Extension: opcache --------------------
RUN set -eux \
	# Installation: Generic
	# Type:         Built-in extension
	&& docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) opcache \
	&& true

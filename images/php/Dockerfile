FROM php:7.4-fpm

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ENV SITE_DOMAIN="mydomain.com"

ARG DEBIAN_FRONTEND=noninteractive

ARG BX_TIMEZONE="Europe/Moscow"

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    dnsutils \
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
    locales \
    tzdata \
    && pecl install mcrypt memcache memcached apcu xdebug imagick zip \
    && docker-php-ext-enable mcrypt memcached apcu xdebug imagick zip \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN docker-php-ext-configure gd \
    --with-jpeg \
    --with-xpm \
    --with-freetype
RUN docker-php-ext-install mysqli gd intl opcache

### localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

#ADD ./php.ini /etc/php/7.4/fpm/conf.d/90-bitrix-php.ini
#ADD ./php.ini /etc/php/7.4/cli/conf.d/90-bitrix-php.ini
ADD ./php.ini /usr/local/etc/php/conf.d/zzz-bitrix-php.ini
ADD ./fpm.conf /usr/local/etc/php-fpm.d/zzz-bitrix-fpm.conf
ADD entrypoint.sh /usr/bin

RUN usermod -u 1000 www-data && \
    chmod 775 /usr/bin/entrypoint.sh

WORKDIR "/var/www/bitrix"

#ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]

EXPOSE 9000

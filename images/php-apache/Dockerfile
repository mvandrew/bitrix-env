FROM php:7.4-apache

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG SITE_DOMAIN="mydomain.com"
ENV SITE_DOMAIN ${SITE_DOMAIN}

ARG DEBIAN_FRONTEND=noninteractive

ARG BX_TIMEZONE="Europe/Moscow"
ENV BX_TIMEZONE ${BX_TIMEZONE}


# Настройки PHP
ARG SET_FUNC_OVERLOAD=0
ENV SET_FUNC_OVERLOAD ${SET_FUNC_OVERLOAD}

ARG MEMORY_LIMIT=2048M
ENV MEMORY_LIMIT ${MEMORY_LIMIT}

ARG PHP_CONFIG_FILE="/usr/local/etc/php/conf.d/zzz-bitrix-php.ini"
ENV PHP_CONFIG_FILE ${PHP_CONFIG_FILE}

ARG PHP_CONFIG_FILE_EX="/usr/local/etc/php/conf.d/zzzz-bitrix-php-ex.ini"
ENV PHP_CONFIG_FILE_EX ${PHP_CONFIG_FILE_EX}


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
    ssl-cert \
    libonig-dev \
    wget \
    && pecl install mcrypt memcache memcached apcu xdebug imagick zip redis \
    && docker-php-ext-install mbstring \
    && docker-php-ext-enable mcrypt memcached apcu xdebug imagick zip redis \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN docker-php-ext-configure gd \
    --with-jpeg \
    --with-xpm \
    --with-freetype
RUN docker-php-ext-install mysqli pdo pdo_mysql gd intl opcache

RUN make-ssl-cert generate-default-snakeoil

### localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN sed -i 's/\/var\/www\/html/\/var\/www\/bitrix/g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/\/var\/www\/html/\/var\/www\/bitrix/g' /etc/apache2/sites-available/default-ssl.conf \
    && a2ensite default-ssl.conf \
    && a2enmod ssl \
    && a2enmod rewrite

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

COPY ./conf/php.ini ${PHP_CONFIG_FILE}

RUN usermod -u 1000 www-data

RUN mkdir /var/www/session \
    && chown www-data:www-data /var/www/session

WORKDIR "/var/www/bitrix"

COPY bitrix-entrypoint.sh /usr/local/bin
ENTRYPOINT [ "bitrix-entrypoint.sh" ]
STOPSIGNAL SIGWINCH

EXPOSE 80 443
CMD ["apache2-foreground"]

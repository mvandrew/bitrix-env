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

ENV PHP_EX_OPCACHE_ENABLED=1

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
    ssl-cert \
    libonig-dev \
    wget \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install -j$(nproc) bz2 bcmath calendar gd pdo pdo_mysql iconv mbstring intl tidy xmlrpc mysqli xsl sockets xml soap opcache \
    && pecl channel-update pecl.php.net \
    && pecl install mcrypt memcache memcached imagick zip oauth igbinary \
    && pecl bundle redis && cd redis && phpize && ./configure --enable-redis-igbinary && make && make install \
    && docker-php-ext-enable mcrypt memcached imagick zip redis oauth opcache \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN make-ssl-cert generate-default-snakeoil

RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
COPY conf/php.ini ${PHP_CONFIG_FILE}

RUN usermod -u 1000 www-data

RUN mkdir /var/www/session \
    && chown -R www-data:www-data /var/www

RUN a2enmod rewrite proxy headers include remoteip ssl

RUN a2dissite 000-default.conf \
    && a2dissite default-ssl.conf

COPY sites-available/bitrix.conf /etc/apache2/sites-available
COPY sites-available/bitrix-ssl.conf /etc/apache2/sites-available
RUN a2ensite bitrix.conf \
    && a2ensite bitrix-ssl.conf

WORKDIR "/var/www/html"

COPY bitrix-entrypoint.sh /usr/local/bin
ENTRYPOINT [ "bitrix-entrypoint.sh" ]
STOPSIGNAL SIGWINCH

EXPOSE 80 443
CMD [ "apache2-foreground" ]

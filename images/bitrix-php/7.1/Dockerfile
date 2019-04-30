FROM php:7.1-apache

LABEL maintainer "Andrey Mishchenko <info@msav.ru>"

ARG DEBIAN_FRONTEND=noninteractive

ENV BX_TIMEZONE="Europe/Moscow"

RUN apt-get update \
    && `# --------------- Install common packages --------------- ` \
    && apt-get -y --no-install-recommends install \
        libmemcached-dev \
        zlib1g-dev \
        libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
        libgif-dev \
        curl \
        wget \
        unzip \
        libzip-dev \
        zip \
        libmagickwand-dev \
        gosu \
    && `# --------------- Install optional packages --------------- ` \
    && apt-get -y --no-install-recommends install \
        git \
        nano \
        mc \
    && `# --------------- Configure PHP extensions --------------- ` \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) mysqli \
    && pecl install imagick \ 
    && docker-php-ext-enable imagick \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install -j$(nproc) zip

# Install & configure PHP debug extension
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug 

# Configure server locale
RUN apt-get -y --no-install-recommends install \
        locales \
        tzdata \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
    && ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

ENV LANG="ru_RU.utf8" \
    BX_PORT="80"

RUN usermod -u 1000 www-data

#RUN `# --------------- Set Apache server HTTP Port --------------- ` \
#    sed -ri /Listen/s/80/${BX_PORT}/ /etc/apache2/ports.conf \
#    && sed -ri /VirtualHost/s/\\*:80/\\*:7755/ /etc/apache2/sites-available/000-default.conf \
RUN `# --------------- Set Global ServerName --------------- ` \
    && echo "ServerName localhost" > /etc/apache2/conf-available/server-name.conf \
    && ln -snf /etc/apache2/conf-available/server-name.conf /etc/apache2/conf-enabled/server-name.conf \
    && `# --------------- Copy default PHP.ini --------------- ` \
    && mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

COPY ./conf.d/php.ini $PHP_INI_DIR/conf.d/user-10-php.ini
COPY ./conf.d/opcache.ini $PHP_INI_DIR/conf.d/user-20-opcache.ini

EXPOSE ${BX_PORT}

COPY ./docker-entrypoint.sh /
RUN chmod 775 /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "apachectl", "-DFOREGROUND" ]

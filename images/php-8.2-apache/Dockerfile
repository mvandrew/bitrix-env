# Используем официальный образ PHP с Apache
FROM php:8.2-apache

# Автор образа
LABEL maintainer="Andrey Mishchenko <msav@msav.ru>"

# Аргументы и переменные окружения
ARG PHP_INI_TYPE_ARG=development
ENV PHP_INI_TYPE=${PHP_INI_TYPE_ARG}
ENV MBSTRING_FUNC_OVERLOAD=2
ENV MEMORY_LIMIT=64M
ENV TZ=Europe/Moscow
ENV USER_ID=1000
ENV GROUP_ID=1000
ENV SITE_DOMAIN=mydomain.ru
ENV SITE_IP=127.0.0.1
ENV PROXY_IPS="127.0.0.1 127.0.0.2"
ENV ACCESS_LOG=/var/log/apache2/access.log
ENV ERROR_LOG=/var/log/apache2/error.log

# Переменные окружения для msmtp
ENV SMTP_ACCOUNT=docker
ENV SMTP_HOST=smtp.example.com
ENV SMTP_PORT=587
ENV SMTP_USER=smtp_user
ENV SMTP_PASSWORD=smtp_password
ENV SMTP_TLS=on
ENV SMTP_EMAIL=from@example.com
ENV SMTP_AUTH=on

# Установка необходимых пакетов, российских сертификатов и PHP-расширений
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    zlib1g-dev \
    libbz2-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libldap2-dev \
    ca-certificates \
    openssl \
    wget \
    msmtp \
    && wget -q -O /usr/local/share/ca-certificates/russian_trusted_root_ca_pem.crt https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt \
    && wget -q -O /usr/local/share/ca-certificates/russian_trusted_sub_ca_pem.crt https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt \
    && update-ca-certificates \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    mbstring \
    xml \
    opcache \
    bz2 \
    calendar \
    curl \
    dom \
    exif \
    fileinfo \
    ftp \
    iconv \
    ldap \
    zip \
    && pecl install apcu && docker-php-ext-enable apcu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Настройка Apache для работы с логами
RUN mkdir -p /var/log/apache2 && \
    touch $ACCESS_LOG $ERROR_LOG && \
    chown -R www-data:www-data /var/log/apache2

# Генерация самоподписного SSL-сертификата
RUN mkdir -p /etc/ssl/private && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/server.key \
    -out /etc/ssl/certs/server.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=MyCompany/OU=IT/CN=${SITE_DOMAIN}"

# Настройка Apache для SSL
RUN a2enmod ssl && \
    a2ensite default-ssl.conf && \
    sed -i 's|SSLCertificateFile.*|SSLCertificateFile /etc/ssl/certs/server.crt|' /etc/apache2/sites-available/default-ssl.conf && \
    sed -i 's|SSLCertificateKeyFile.*|SSLCertificateKeyFile /etc/ssl/private/server.key|' /etc/apache2/sites-available/default-ssl.conf

# Копируем файл конфигурации php.ini
COPY php-opcache.ini /usr/local/etc/php/conf.d/php-opcache.ini
COPY zbx-php.ini /usr/local/etc/php/conf.d/zbx-php.ini

# Копируем конфигурацию Apache из файла bitrix-httpd.conf
COPY bitrix-httpd.conf /etc/apache2/conf-available/bitrix-httpd.conf
RUN a2enconf bitrix-httpd

# Копируем и назначаем права на стартовый скрипт
COPY bitrix-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/bitrix-entrypoint.sh

# Обеспечение корректной работы директив `.htaccess`
RUN a2enmod rewrite

# Добавление служебных каталогов
RUN mkdir /var/www/session \
    && mkdir /var/www/common \
    && chown -R www-data:www-data /var/www

VOLUME ["/var/www/html", "/var/www/session", "/var/log/apache2"]

# Установка рабочего каталога
WORKDIR /var/www/html

# Конфигурация Apache
EXPOSE 80 443

# Установка стартового скрипта как основного для запуска
ENTRYPOINT ["/usr/local/bin/bitrix-entrypoint.sh"]
CMD ["apache2-foreground"]

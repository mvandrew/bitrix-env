FROM mariadb:10.3

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG SITE_TIMEZONE="Europe/Moscow"
ENV SITE_TIMEZONE ${SITE_TIMEZONE}

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        locales \
        tzdata \
        debconf \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN ln -snf /usr/share/zoneinfo/${SITE_TIMEZONE} /etc/localtime \
    && echo ${SITE_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN mkdir /etc/mysql/bitrix.d

COPY bitrix.cnf /etc/mysql/bitrix.cnf

RUN echo "!include /etc/mysql/bitrix.cnf" >> /etc/mysql/my.cnf

VOLUME /etc/mysql/bitrix.d

CMD ["mysqld"]

EXPOSE 3306

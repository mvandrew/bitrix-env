FROM mysql:5.7

LABEL ru.msav.image.authors="Andrey Mishchenko <msav@msav.ru>"

ARG SITE_TIMEZONE="Europe/Moscow"
ENV SITE_TIMEZONE ${SITE_TIMEZONE}

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    locales \
    tzdata \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN ln -snf /usr/share/zoneinfo/${SITE_TIMEZONE} /etc/localtime \
    && echo ${SITE_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

ADD ./conf/bitrix.cnf /etc/mysql/conf.d/zz-bitrix.cnf

CMD [ "mysqld" ]

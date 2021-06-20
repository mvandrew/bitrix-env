FROM mysql:5

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG BX_TIMEZONE="Europe/Moscow"

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    locales \
    tzdata \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && echo ${BX_TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

ADD bitrix.cnf /etc/mysql/conf.d/zz-bitrix.cnf

CMD ["mysqld"]

EXPOSE 3306

FROM mariadb:10.3

LABEL ru.msav.image.authors="Andrey Mishchenko <info@msav.ru>"

ARG TIMEZONE="Europe/Moscow"
ENV TIMEZONE ${TIMEZONE}

# Настройки СУБД
ARG innodb_buffer_pool_size=12G
ENV innodb_buffer_pool_size ${innodb_buffer_pool_size}
ARG innodb_buffer_pool_instances=12
ENV innodb_buffer_pool_instances ${innodb_buffer_pool_instances}
ARG innodb_log_file_size=1G
ENV innodb_log_file_size ${innodb_log_file_size}

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    locales \
    tzdata \
    wget \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo ${TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

ADD ./conf/bitrix.cnf /etc/mysql/conf.d/zz-bitrix.cnf

COPY bitrix-entrypoint.sh /usr/local/bin
ENTRYPOINT [ "bitrix-entrypoint.sh" ]

EXPOSE 3306

CMD [ "mysqld", "--user=root" ]

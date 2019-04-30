FROM mysql:5.7

LABEL maintainer "Andrey Mishchenko <info@msav.ru>"

ENV BX_TIMEZONE="Europe/Moscow" \
    MYSQL_ROOT_PASSWORD="bitrix_pwd" \
    MYSQL_DATABASE="bitrix_db" \
    MYSQL_USER="bitrix_sa" \
    MYSQL_PASSWORD="bitrix_sa_pwd"

RUN apt-get update \
    && `# --------------- Install optional packages --------------- ` \
    && apt-get -y --no-install-recommends install \
        net-tools \
        nano \
        mc

# Configure server locale
RUN apt-get -y --no-install-recommends install \
        locales \
        tzdata \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
    && ln -snf /usr/share/zoneinfo/${BX_TIMEZONE} /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

ENV LANG="ru_RU.utf8"

ADD ./conf.d/my.cnf /etc/mysql/conf.d/zz-bitrix.cnf

# Download MySQLTuner
ADD https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl /root
RUN chmod 775 /root/mysqltuner.pl

EXPOSE 3306
CMD [ "mysqld" ]

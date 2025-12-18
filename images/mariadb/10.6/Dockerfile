# MariaDB 10.6 for 1C-Bitrix (Legacy compatibility)
# Optimized configuration with UTF8MB4 and Bitrix-compatible settings
#
# Build from parent directory:
#   cd .. && docker build -t msav/bitrix-mariadb:10.6 -f 10.6/Dockerfile .
#
# Override InnoDB settings by mounting custom config:
#   -v ./my-custom.cnf:/etc/mysql/bitrix.d/custom.cnf

FROM mariadb:10.6

LABEL maintainer="Andrey Mishchenko <info@msav.ru>"
LABEL org.opencontainers.image.title="Bitrix MariaDB"
LABEL org.opencontainers.image.version="10.6"
LABEL org.opencontainers.image.description="MariaDB 10.6 for legacy 1C-Bitrix projects"
LABEL org.opencontainers.image.vendor="msav.ru"
LABEL org.opencontainers.image.source="https://github.com/mvandrew/bitrix-env"

# Timezone configuration
ARG SITE_TIMEZONE="Europe/Moscow"
ENV TZ=${SITE_TIMEZONE}

# Install required packages and configure timezone
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        locales \
        tzdata; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    # Configure timezone
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    # Create directory for custom configs
    mkdir -p /etc/mysql/bitrix.d; \
    # Generate UTF-8 locale
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen

# Copy Bitrix-optimized configuration (production by default)
# Use 99- prefix to ensure it loads last and overrides defaults
COPY --chmod=644 base/conf/bitrix-prod.cnf /etc/mysql/conf.d/99-bitrix.cnf

# Health check for container orchestration
# Uses mysqladmin ping (legacy command available in 10.6)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD mysqladmin ping -h localhost -u root --password="${MYSQL_ROOT_PASSWORD}" || exit 1

# Volumes for data persistence and custom configuration
VOLUME ["/var/lib/mysql", "/etc/mysql/bitrix.d"]

EXPOSE 3306

CMD ["mysqld"]

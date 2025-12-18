FROM node:14

LABEL ru.msav.image.authors="Andrey Mishchenko <msav@msav.ru>"

RUN npm install --global gulp-cli

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 775 /entrypoint.sh

WORKDIR "/app"

ENTRYPOINT [ "/entrypoint.sh" ]

#!/bin/bash

if [ ! -f package.json ]; then
  npm init -y
  npm install gulp
fi

npm install

exec "$@"

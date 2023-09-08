#!/bin/sh

set -e

COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"

echo "PASSING ENVIRONMENT FROM $ENV_FILE"

while read line; do
  echo "$line"
  echo "$line" >> $GITHUB_ENV
done < $ENV_FILE

printenv
yarn install
yarn lint
yarn add start-server-and-test
yarn build --modern=client
yarn start-server-and-test start "http://localhost:$SERVICE_PORT" "$COMMAND" --timeout $READINESS_TIMEOUT

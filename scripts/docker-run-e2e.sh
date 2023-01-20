#!/bin/sh

set -e

IMAGE_NAME="$1"
IMAGE_TAG="$2"
DOCKER_ARGS="$3"
COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$7"

HOST_PORT=8080
CONTAINER_NAME="${IMAGE_NAME}_${IMAGE_TAG}"

if [ -z "$SERVCICE_PORT" ]; then
  #apt-get update
  CONTAINER_PORT=$(docker inspect --format='{{json .Config.ExposedPorts}}' "$IMAGE_NAME:$IMAGE_TAG" | jq 'keys[0]' | cut -d'/' -f1 | cut -d'"' -f2)
  echo "Detected image port: $CONTAINER_PORT"
else
  CONTAINER_PORT=$SERVCICE_PORT
fi
echo "run --rm -d -p \"$HOST_PORT:$CONTAINER_PORT\" --name \"$CONTAINER_NAME\" --env-file \"$ENV_FILE\" $DOCKER_ARGS \"$IMAGE_NAME:$IMAGE_TAG\""
docker run --rm -d -p "$HOST_PORT:$CONTAINER_PORT" --name "$CONTAINER_NAME" --env-file "$ENV_FILE" $DOCKER_ARGS "$IMAGE_NAME:$IMAGE_TAG"

attempts=0
max_attempts=60
while [ $attempts -lt $max_attempts ]; do
  if curl --silent --head --fail "https://localhost:$HOST_PORT/"; then
    echo "Service started"
    break
  else
    echo "Waiting for service to start..."
    sleep 1
    attempts=$((attempts+1))
  fi
done
if [ $attempts -eq $max_attempts ]; then
  echo "Maximum number of attempts reached, server still not operational"
  exit 1
fi

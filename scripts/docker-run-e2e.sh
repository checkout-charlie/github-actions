#!/bin/sh
IMAGE_NAME="$1"
IMAGE_TAG="$2"
DOCKER_ARGS="$3"
COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"

HOST_PORT=8080
CONTAINER_NAME=${IMAGE_NAME}_${IMAGE_TAG}

if [ -z "$SERVCICE_PORT" ]; then
  CONTAINER_PORT=$SERVCICE_PORT
else
  #apt-get update
  apt-get install -y jq
  CONTAINER_PORT=$(docker inspect --format='{{json .Config.ExposedPorts}}' "{$IMAGE_NAME}:{$IMAGE_TAG}" | jq 'keys[0]')
  echo "Detected container port: $CONTAINER_PORT"
fi

docker run --rm -d -p $HOST_PORT:$SERVICE_PORT --env-file "$ENV_FILE" $DOCKER_ARGS "$IMAGE_NAME:$IMAGE_TAG" --name "$CONTAINER_NAME"

# Perform readiness check
timeout=60
i=0
while true; do
    if nc -z localhost $HOST_PORT; then
        echo "Service is ready"
        docker exec $CONTAINER_NAME -- $COMMAND
        exit 0
    fi

    i=$((i + 1))
    if [ $i -ge $timeout ]; then
        echo "Timeout reached waiting for service to be ready"
        exit 1
    fi

    sleep 1
done
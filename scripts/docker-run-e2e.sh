#!/bin/sh

set -e

IMAGE_NAME="$1"
IMAGE_TAG="$2"
DOCKER_ARGS="$3"
COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"
READINESS_TIMEOUT="$7"

HOST_PORT=8080
CONTAINER_NAME="${IMAGE_NAME}_${IMAGE_TAG}"

if [ -z "$SERVICE_PORT" ]; then
  #apt-get update
  CONTAINER_PORT=$(docker inspect --format='{{json .Config.ExposedPorts}}' "$IMAGE_NAME:$IMAGE_TAG" | jq 'keys[0]' | cut -d'/' -f1 | cut -d'"' -f2)
  echo "Detected image port: $CONTAINER_PORT"
else
  CONTAINER_PORT=$SERVICE_PORT
fi

docker run --rm -d -p "$HOST_PORT:$CONTAINER_PORT" --cap-add=SYS_ADMIN --name "$CONTAINER_NAME" --env-file "$ENV_FILE" -e HOST="0.0.0.0" -e "TERM=xterm-color" $DOCKER_ARGS "$IMAGE_NAME:$IMAGE_TAG" || exit 1

# Wait for container to start and run tests
attempts=0
max_attempts=$READINESS_TIMEOUT
while [ $attempts -lt $max_attempts ]; do
  if curl --head --silent --fail "http://localhost:$HOST_PORT/"; then
    echo "Service started, running test..."
      # Allow using headless chrome sandbox
      docker exec -u root "$CONTAINER_NAME" /bin/sh -c "mkdir /etc/sysctl.d/; echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/userns.conf" || exit 1

      # display env vars
      docker exec -u "$CONTAINER_NAME" /bin/sh -c "printenv" || exit 1

       # Execute tests
      docker exec "$CONTAINER_NAME" /bin/sh -c "$COMMAND" || exit 1
    break
  else
    echo "Waiting for service to start..."
    sleep 1
    attempts=$((attempts+1))
  fi
done
if [ $attempts -eq $max_attempts ]; then
  echo "Maximum number of attempts reached, container still not operational"
  exit 1
fi

#!/bin/sh

set -e

IMAGE_NAME="$1"
IMAGE_TAG="$2"
DOCKER_ARGS="$3"
COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"
READINESS_TIMEOUT="$7"
SCREENSHOTS_PATH="$8"

HOST_PORT=3000
CONTAINER_NAME="${IMAGE_NAME}_${IMAGE_TAG}"

FAILED=0

if [ -z "$SERVICE_PORT" ]; then
  CONTAINER_PORT=$(docker inspect --format='{{json .Config.ExposedPorts}}' "$IMAGE_NAME:$IMAGE_TAG" | jq 'keys[0]' | cut -d'/' -f1 | cut -d'"' -f2)
  echo "Detected image port: $CONTAINER_PORT"
else
  CONTAINER_PORT=$SERVICE_PORT
fi

if [ -z "$SCREENSHOTS_PATH" ]; then
  MOUNTS_PART=""
else
  SCREENSHOTS_PATH_LOCAL="${PWD}/test-artifacts/screenshots/${IMAGE_NAME}/"
  mkdir -p "$SCREENSHOTS_PATH_LOCAL"
  chmod 777 "$SCREENSHOTS_PATH_LOCAL"
  MOUNTS_PART=" -v ${SCREENSHOTS_PATH_LOCAL}:${SCREENSHOTS_PATH}/"
  echo "Set mount: $MOUNTS_PART"
fi

# Run the container
docker run --rm -d -p "$HOST_PORT:$CONTAINER_PORT" --cap-add=SYS_ADMIN --name "$CONTAINER_NAME" $MOUNTS_PART --env-file "$ENV_FILE" -e HOST="0.0.0.0" -e "TERM=xterm-color" $DOCKER_ARGS "$IMAGE_NAME:$IMAGE_TAG" || exit 1

# Wait for container to start and run tests
attempts=0
max_attempts=$READINESS_TIMEOUT
while [ $attempts -lt $max_attempts ]; do
  if curl --fail "http://localhost:$HOST_PORT/"; then
    echo "Service started, running test..."
     docker exec -u root "$CONTAINER_NAME" /bin/sh -c "mkdir -p /etc/sysctl.d/; echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/userns.conf"  || exit 1

      # Print env vars
      docker exec "$CONTAINER_NAME" /bin/sh -c "printenv" || exit 1

      # Run tests
      docker exec "$CONTAINER_NAME" /bin/sh -c "$COMMAND" || FAILED=1

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

# Print container logs
echo "#########################################"
echo "########### SERVER LOGS #################"
echo "#########################################"
docker logs "$CONTAINER_NAME"
echo "#########################################"
echo "######### END OF SERVER LOGS ############"
echo "#########################################"

#echo "Listing artifacts on ${SCREENSHOTS_PATH_LOCAL}"
#ls -als "${SCREENSHOTS_PATH_LOCAL}" || echo "No artifacts."

exit $FAILED


#!/bin/sh

set -e

BUILD_CONTEXT="$1"
DOCKERFILE="$2"
BUILD_ARGS="$3"
IMAGE_NAME="$4"
MULTI_STAGE="$5"
TESTING_TAG="$6"
PRODUCTION_STAGE="$7"
TESTING_STAGE="$8"

echo "Image before build:"
docker images

# Removed remote tag locally
if [ "$MULTI_STAGE" != "false" ]
then
	echo "Building image..."
  docker build $BUILD_ARGS --file "$DOCKERFILE" --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
  echo "Building test image..."
  echo "docker build $BUILD_ARGS --file \"$DOCKERFILE\" --target \"$TESTING_STAGE\" -t \"$IMAGE_NAME:$TESTING_TAG\" \"$BUILD_CONTEXT\""
  docker build $BUILD_ARGS --file "$DOCKERFILE" --target "$TESTING_STAGE" -t "$IMAGE_NAME:$TESTING_TAG" "$BUILD_CONTEXT" || exit 1
else
  if [ "$PRODUCTION_STAGE" != "production" ]
  then
    echo "Building image at stage: $PRODUCTION_STAGE"
    docker build $BUILD_ARGS --file "$DOCKERFILE" --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
  else
    echo "Building image..."
    docker build $BUILD_ARGS --file "$DOCKERFILE" -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
  fi
fi
echo "Post-build image list:"
docker images
echo "Cleanup unused Docker resources.."
# Remove unused resources that would otherwise persist between builds by virtue of GH dependency caching
docker rmi -f $(docker images | awk '$2 != "latest" && $2 != "testing" {print $3}') >/dev/null 2>&1 || exit 0
docker system prune -f
echo "Image list after cleanup:"
docker images
echo "List of containers:"
docker ps -a
echo "Done."

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
  echo "Building image..."
  docker build $BUILD_ARGS --file "$DOCKERFILE" -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
fi
echo "Post-build image list:"
docker images
echo "Cleanup unused Docker resources.."
# Remove unused resources that would otherwise persist between builds by virtue of GH dependency caching
docker system prune -f
echo "Image list after cleanup:"
docker images
echo "List of containers:"
docker ps -a
echo "Done."

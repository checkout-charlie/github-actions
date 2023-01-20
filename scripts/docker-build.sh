#!/bin/sh

set -e


BUILD_CONTEXT="$1"
BUILD_ARGS="$2"
IMAGE_NAME="$3"
MULTI_STAGE="$4"
TESTING_TAG="$5"
PRODUCTION_STAGE="$6"
TESTING_STAGE="$7"
ADDITIONAL_TAG="$8"

if [ -z "$COMMIT_HASH" ]; then
  ADDITIONAL_TAG_COMMAND=""
else
  ADDITIONAL_TAG_COMMAND="-t $IMAGE_NAME:$ADDITIONAL_TAG"
fi

# Removed remote tag locally
if [ "$MULTI_STAGE" != "false" ]
then
	echo "Building image..."
  docker build $BUILD_ARGS --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:latest" $ADDITIONAL_TAG_COMMAND "$BUILD_CONTEXT" \
  && echo "Building test image..." \
  && docker build $BUILD_ARGS --target "$TESTING_STAGE" -t "$IMAGE_NAME:testing" "$BUILD_CONTEXT"
else
  echo "Building image..."
  docker build $BUILD_ARGS -t "$IMAGE_NAME:latest" $ADDITIONAL_TAG_COMMAND "$BUILD_CONTEXT"
fi

echo "Cleanup.."
docker system prune -f
echo "Done."

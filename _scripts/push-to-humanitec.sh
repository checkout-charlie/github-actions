#!/bin/sh

set -e

key_from_json_obj ()
{
	tr -d '\n' | sed 's/^[ \t\v\f]*{.*"'"${1}"'"[ \t\v\f]*:[ \t\v\f]*"\([^"]*\)"[ \t\v\f]*[,}].*$/\1/'
}

fetch_url ()
{
	method="$1"
	payload=""
	if [ "$method" = "POST" ] || [ "$method" = "PUT" ] || [ "$method" = "PATCH" ]
	then
		payload="$2"
		shift
	fi
	url="$2"
	auth_header="Authorization: Bearer $HUMANITEC_TOKEN"
  if [ "$payload" != "" ]
  then
    curl \
      -X "$method" \
      -H "$auth_header" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "$url"
  else
    curl \
      -X "$method" \
      -H "$auth_header" \
      "$url"
  fi
}


export HUMANITEC_ORG="$1"
export HUMANITEC_TOKEN="$2"
IMAGE_NAME="$3"
LOCAL_TAG="$4"


if [ -z "$HUMANITEC_ORG" ]
then
	echo "No Organization specified as option or via HUMANITEC_ORG environment variable." >&2
	exit 1

fi

if [ -z "$HUMANITEC_TOKEN" ]
then
	echo "No token specified as option or via HUMANITEC_TOKEN environment variable." >&2
	exit 1
fi

if [ -z "$IMAGE_NAME" ]
then
	echo "No IMAGE_NAME provided." >&2
	exit 1
fi


if [ -z "$IMAGE_NAME" ]
then
	echo "No IMAGE_STAGE provided." >&2
	exit 1
fi

echo "Retrieving registry credentials"
registry_json="$(fetch_url GET "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/registries/humanitec/creds")"
echo "${registry_json}"
if [ $? -ne 0 ]
then
	echo "Unable to retrieve credentials for humanitec registry." >&2
	exit 1
fi

username="$(echo "$registry_json" | key_from_json_obj "username")"
password="$(echo "$registry_json" | key_from_json_obj "password")"
server="$(echo "$registry_json" | key_from_json_obj "registry")"

commit="$(git rev-parse HEAD)"
local_image_and_tag="${IMAGE_NAME}:${LOCAL_TAG}"
destination_image_name="${server}/${HUMANITEC_ORG}/${IMAGE_NAME}"
destination_image_and_tag="${server}/${HUMANITEC_ORG}/${IMAGE_NAME}:${commit}"

echo "Local image and tag: ${local_image_and_tag}"
echo "Destination image and tag: ${destination_image_and_tag}"

echo "Logging into docker registry"
echo "${password}" | docker login -u "${username}" --password-stdin "${server}"
if [ $? -ne 0 ]
then
	echo "Unable to log into humanitec registry." >&2
	exit 1
fi

if ! docker tag "$local_image_and_tag" "$destination_image_and_tag"
then
	echo "Error pushing to remote registry: Cannot retag locally." >&2
	exit 1
fi

echo "Pushing image to registry: $destination_image_and_tag"
if ! docker push "$destination_image_and_tag"
then
	echo "Error pushing to remote registry: Push failed." >&2
	exit 1
fi


echo "Notifying Humanitec"
payload="{\"commit\":\"${commit}\",\"ref\":\"${GITHUB_REF}\",\"version\":\"${commit}\",\"name\":\"registry.humanitec.io/${HUMANITEC_ORG}/${IMAGE_NAME}\",\"type\":\"container\"}"
echo "Humanitec notification payload: ${payload}"
if ! fetch_url POST "$payload" "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/artefact-versions"
then
        echo "Unable to notify Humanitec." >&2
        exit 1
fi
echo "Image list after push:"
docker images
# Removed remote tag locally
docker stop $(docker ps -a -q) || echo "No containers to stop"
docker images | grep "$destination_image_name" | awk '{print $1 ":" $2}' | xargs -I{} docker image rm {}
echo "Image list after cleanup:"
docker images

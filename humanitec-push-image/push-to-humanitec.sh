#!/bin/sh

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
	if command -v curl &> /dev/null
	then
		if [ "$payload" != "" ]
		then
			curl --fail -s \
				-X "$method" \
				-H "$auth_header" \
				-H "Content-Type: application/json" \
				-d "$payload" \
				"$url"
		else
			curl --fail -s \
				-X "$method" \
				-H "$auth_header" \
				"$url"
		fi
    	elif command -v wget &> /dev/null
	then
		if [ "$payload" != "" ]
		then
			wget --quiet -O - \
				--method="$method" \
				--header="$auth_header" \
				--header="Content-Type: application/json" \
				--body-data="$payload" \
				"$url"
		else
			wget --quiet -O - \
				--method="$method" \
				--header="$auth_header" \
				"$url"
		fi
	else
		echo "System does not have the commands wget or curl installed." >&2
		exit 1
	fi
}

api_prefix="https://api.humanitec.io"

image_name="$2"
export HUMANITEC_TOKEN="$1"
export HUMANITEC_ORG="checkout-charlie"

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

if [ -z "$image_name" ]
then
	echo "No IMAGE_NAME provided." >&2
	exit 1
fi

echo "Retrieving registry credentials"
registry_json="$(fetch_url GET "${api_prefix}/orgs/${HUMANITEC_ORG}/registries/humanitec/creds")"
echo "${registry_json}"
if [ $? -ne 0 ]
then
	echo "Unable to retrieve credentials for humanitec registry." >&2
	exit 1
fi

username="$(echo "$registry_json" | key_from_json_obj "username")"
password="$(echo "$registry_json" | key_from_json_obj "password")"
server="$(echo "$registry_json" | key_from_json_obj "registry")"

echo
commit="$(git rev-parse HEAD)"
local_tag="${image_name}:${commit}"
remote_tag="${server}${HUMANITEC_ORG}/$local_tag"
ref="$(git rev-parse --symbolic-full-name HEAD)"

echo "Logging into docker registry"
echo "${password} | docker login -u ${username} --password-stdin ${server}"
echo "${password}" | docker login -u "${username}" --password-stdin "${server}"
if [ $? -ne 0 ]
then
	echo "Unable to log into humanitec registry." >&2
	exit 1
fi

if ! docker tag "$local_tag" "$remote_tag"
then
	echo "Error pushing to remote registry: Cannot retag locally." >&2
	exit 1
fi

echo "Pushing image to registry: $remote_tag"
if ! docker push "$remote_tag"
then
	echo "Error pushing to remote registry: Push failed." >&2
	exit 1
fi

echo "Notifying Humanitec"
payload="{\"commit\":\"${commit}\",\"ref\":\"${ref}\",\"version\":\"${commit}\",\"name\":\"${image_name}\",\"type\":\"container\"}"
if ! fetch_url POST "$payload" "${api_prefix}/orgs/${HUMANITEC_ORG}/artefact-versions"
then
        echo "Unable to notify Humanitec." >&2
        exit 1
fi

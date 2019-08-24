#!/bin/sh -l

set -e

#
# Since Github doesn't seem to verify the `required: true` param, it has to be done here…
#

input_error() {
  >&2 printf "\nERR: Invalid input: '%s' is required, and must be specified.\n\n" "$1"
  >&2 printf "\tNote: It's the %s\n" "$2"
  >&2 printf "Try:\n"
  >&2 printf "\tuses: meeDamian/sync-readme@TAG\n"
  >&2 printf "\twith:\n"
  >&2 printf "\t  user: \${{ secrets.DOCKER_USER }}\n"
  >&2 printf "\t  pass: \${{ secrets.DOCKER_PASS }}\n"
  >&2 printf "\t  slug: \${{ github.repository }}\n\n"
  exit 1
}

if [ -z "${INPUT_USER}" ]; then
  input_error "user" "username used to login to Docker Hub."
fi

if [ -z "${INPUT_PASS}" ]; then
  input_error "pass" "password used to login to Docker Hub."
fi

if [ -z "${INPUT_SLUG}" ]; then
  input_error "slug" "image name used to pull images from Docker Hub (ex. meedamian/simple-qemu) "
fi

DOCKERHUB_API="https://hub.docker.com/v2"

# If no README.md path is provided, use one at the root of the repo
README=${INPUT_README:-./README.md}

if [ ! -f "${README}" ]; then
  >&2 printf "\nERR: '%s' file doesn't exit\n\n" "${README}"
  >&2 printf "Either create it, or point to the one you want to be used with:\n"
  >&2 printf "\tuses: meeDamian/sync-readme@TAG\n"
  >&2 printf "\twith:\n"
  >&2 printf "\t  ...\n"
  >&2 printf "\t  readme: PATH_TO_FILE\n"
  exit 1
fi

# Github allows mixed case slugs.  Docker Hub doesn't, and requires lowercase only.
# It's annoying.  The lines below fix that common mistake.
SLUG="$(echo "${INPUT_SLUG}" | awk '{print(tolower($0))}')"
USER="$(echo "${INPUT_USER}" | awk '{print(tolower($0))}')"

printf "Syncing %s to %s…\t" "${README}" "${SLUG}"

# First GET $TOKEN from the /login endpoint
TOKEN=$(jq -n \
  --arg username "${USER}" \
  --arg password "${INPUT_PASS}" \
  '{$username, $password}' \
  | curl -sH "Content-Type: application/json"  -d @-  "${DOCKERHUB_API}/users/login" \
  | jq -r 'select(.token != null)')

# Terminate here if token is not available
if [ -z "${TOKEN}" ]; then
  >&2 printf "\n\tERR: unable to get access token.  Make sure your Docker Hub credentials are correct.\n"
  exit 1
fi

# Try to PATCH $SLUG full_description with the contents of $README file
CODE=$(jq -n \
  --arg full_description "$(cat "${README}")" \
  '{"registry": "registry-1.docker.io", $full_description}' \
  | curl -sL  -X PATCH  -d @-  -o /dev/null \
      -H "Content-Type: application/json" \
      -H "Authorization: JWT ${TOKEN}" \
      -w "%{http_code}" "${DOCKERHUB_API}/repositories/${SLUG}/")

if [ "${CODE}" != "200" ]; then
  printf "\n\tERR: Unable to update description on Docker Hub\n"
  exit 1
fi

printf "done\n"

#!/bin/sh -l

set -e

#
# Since Github doesn't seem to verify the `required: true` param, it has to be done here…
#
if [ -z "${INPUT_PASS}" ]; then
  >&2 printf "\nERR: Invalid input: 'pass' is required, and must be specified.\n\n"
  >&2 printf "\tNote: It's the password used to login to Docker Hub.\n"
  >&2 printf "Try:\n"
  >&2 printf "\tuses: meeDamian/sync-readme@TAG\n"
  >&2 printf "\twith:\n"
  >&2 printf "\t  ...\n"
  >&2 printf "\t  pass: \${{ secrets.DOCKER_PASS }}\n"
  exit 1
fi

# If no README.md path is provided, use one at the root of the repo
README=${INPUT_README:-./README.md}

if [ ! -f "${README}" ]; then
  >&2 printf "\nERR: '%s' file doesn't exit\n\n" "${README}"
  >&2 printf "Either create it, or point to the file you want to be used with:\n"
  >&2 printf "\tuses: meeDamian/sync-readme@TAG\n"
  >&2 printf "\twith:\n"
  >&2 printf "\t  ...\n"
  >&2 printf "\t  readme: PATH_TO_FILE\n\n"
  exit 1
fi

# Github allows mixed case slugs.  Docker Hub doesn't, and requires lowercase only.
# It's annoying.  The lines below fix that common mistake.
SLUG="$(echo "${INPUT_SLUG:-${GITHUB_REPOSITORY}}" | awk '{print(tolower($0))}')"
USER="$(echo "${INPUT_USER:-${GITHUB_ACTOR}}"      | awk '{print(tolower($0))}')"

DOCKERHUB_API="https://hub.docker.com/v2"

printf "Syncing %s to %s…\t" "${README}" "${SLUG}"

# First GET $TOKEN from the /login endpoint
TOKEN=$(jq -nc \
  --arg username "${USER}" \
  --arg password "${INPUT_PASS}" \
  '{$username, $password}' \
  | curl -sH "Content-Type: application/json"  -d @-  "${DOCKERHUB_API}/users/login" \
  | jq -r 'select(.token != null) | .token')

# Terminate here if token is not available
if [ -z "${TOKEN}" ]; then
  >&2 printf "\n\tERR: unable to get access token.  Make sure your Docker Hub credentials are correct.\n"
  exit 1
fi

# By default, do nothing
DESC=null

# If something was indeed passed to `description:`, then…
if [ -n "${INPUT_DESCRIPTION}" ]; then
  # Add extra quotes, to make it a valid JSON string
  DESC="\"${INPUT_DESCRIPTION}\""

  # If it was set to `true`, then fetch from Github.
  #   No quoting necessary, as it either returns a valid JSON string, or null
  if [ "${INPUT_DESCRIPTION}" = "true" ]; then
    DESC=$(curl -s "https://api.github.com/repos/${SLUG}" | jq '.description')
  fi
fi

# Try to PATCH $SLUG full_description with the contents of $README file
#   Note: `| del(.[] | nulls)` part removes `description:` key from object, to prevent overwriting it.
#   Note: `--argjson` is used so that `null` is a valid value, that can be easily filtered-out later.
CODE=$(jq -nc \
  --arg full_description "$(cat "${README}")" \
  --argjson description "${DESC}" \
  '{"registry": "registry-1.docker.io", $full_description, $description} | del(.[] | nulls)' \
  | curl -sL  -X PATCH  -d @-  -o /tmp/out \
      -H "Content-Type: application/json" \
      -H "Authorization: JWT ${TOKEN}" \
      -w "%{http_code}" "${DOCKERHUB_API}/repositories/${SLUG}/")

if [ "${CODE}" != "200" ]; then
  printf "\n\tERR: Unable to update description on Docker Hub\n"
  cat /tmp/out
  exit 1
fi

printf "done\n"

#!/bin/bash

set -e

exec 3>&1
exec 1>&2

set +x
echo "machine ${SMUGGLER_host} login ${SMUGGLER_user} password ${SMUGGLER_pass}" > ~/.netrc

job_url="https://${SMUGGLER_host}${SMUGGLER_job}"

while true; do
  set -x
  curl -sS --max-time 10 --retry 3 -n "${job_url}/${SMUGGLER_VERSION_ID}/api/json" > "${SMUGGLER_DESTINATION_DIR}/raw"
  set +x

  jq -r '.result' < "${SMUGGLER_DESTINATION_DIR}/raw" > "${SMUGGLER_DESTINATION_DIR}"/result
  jq -r '.url'    < "${SMUGGLER_DESTINATION_DIR}/raw" > "${SMUGGLER_DESTINATION_DIR}"/url

  time_ms=$(jq -r '.timestamp' <  "${SMUGGLER_DESTINATION_DIR}/raw")
  echo "${time_ms}"     > "${SMUGGLER_DESTINATION_DIR}"/start_time_ms
  echo "${time_ms%???}" > "${SMUGGLER_DESTINATION_DIR}"/start_time_s

  {
    printf 'date='
    date -d @"$(cat "${SMUGGLER_DESTINATION_DIR}"/start_time_s)"

    printf 'build_id=%s\n' "${SMUGGLER_VERSION_ID}"
    printf 'url=%s\n'      "$(cat "${SMUGGLER_DESTINATION_DIR}"/url)"
    printf 'result=%s\n'   "$(cat "${SMUGGLER_DESTINATION_DIR}"/result)"
  } > "${SMUGGLER_OUTPUT_DIR}"/metadata

  if [[ -z "${SMUGGLER_requireResult:-}" ]]; then
    echo "Don't care about the result, so all done!" >&2
    break
  elif [[ "$(cat "${SMUGGLER_DESTINATION_DIR}"/result)" == "null" ]]; then
    echo "Waiting for build..." >&2
    sleep 10
  elif [[ "$(cat "${SMUGGLER_DESTINATION_DIR}"/result)" == "${SMUGGLER_requireResult}" ]]; then
    echo "Got the result we were looking for (${SMUGGLER_requireResult}), all done!" >&2
    break
  else
    echo "Wrong result, wanted ${SMUGGLER_requireResult} and got $(cat "${SMUGGLER_DESTINATION_DIR}"/result)" >&2
    exit 1
  fi
done

#!/bin/bash

set -e

exec 3>&1
exec 1>&2

set +x
echo "machine ${SMUGGLER_host} login ${SMUGGLER_user} password ${SMUGGLER_pass}" > ~/.netrc

job_url="https://${SMUGGLER_host}${SMUGGLER_job}"

if [[ -n "${SMUGGLER_buildParams:-}" ]]; then
  set -x
  curl -sS -X POST -D headers --max-time 10 --retry 3 -n "${job_url}/buildWithParameters" -d "${SMUGGLER_buildParams}"
  set +x
else
  set -x
  curl -sS -X POST -D headers --max-time 10 --retry 3 -n "${job_url}/build"
  set +x
fi

queue=$(grep '^Location: ' headers | cut -d ' ' -f 2- | sed -e 's/[[:space:]]*$//')

n=0
until [[ $n -ge 20 ]]; do
  set -x
  jobid=$(curl -sS --max-time 10 --retry 3 -n "${queue}/api/json" | jq '.executable.number')
  set +x

  if [[ "${jobid}" == "null" ]]; then
    echo "Build is not scheduled yet ${n}/20" >&2
    sleep 3
  else
    echo "Build scheduled, jobid ${jobid}" >&2
    echo "${jobid}" > "${SMUGGLER_OUTPUT_DIR}/versions"
    break
  fi
done

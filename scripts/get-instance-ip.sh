#!/bin/bash
set -o nounset
set -o errexit

check-dependencies() {
  local DEPS=( curl jq shyaml )
  for i in "${DEPS[@]}"
  do
    if ! which ${i} >/dev/null; then
      echo ${i} must be installed
      exit 1
    fi
  done
}

get-job-id()
{
  while IFS=' ' read -ra word
  do
      if [[ $word != *[!0-9]* ]]; then
          #echo "'$word' is strictly numeric"
          JOB_ID=$word
      fi
  done < JOB_OUTPUT
}

get-instance-ip() {
  local TOWER_HOST=$(tower-cli config host | shyaml get-value host)
  local TOWER_USERNAME=$(tower-cli config username | shyaml get-value username)
  local TOWER_PASSWORD=$(tower-cli config password | shyaml get-value password)
  local JOB_DATA=$(curl -s -k -H "Accept: application/json" \
    --user ${TOWER_USERNAME}:${TOWER_PASSWORD} \
    https://${TOWER_HOST}/api/v1/jobs/${JOB_ID}/job_events/?task__exact=instance%20ip\&event__exact=runner_on_ok)
  local IP=$(echo ${JOB_DATA} | jq .results[0].event_data.res.msg)
  echo ${IP//\"/''}
}

main() {
  check-dependencies
  get-job-id
  get-instance-ip
}

main

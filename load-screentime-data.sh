#!/usr/bin/env bash

# Pulls data from ActivityWatch and ships it to an n8n Webhook using basic auth
# Values are provided via the following environment variables:
# - WEBHOOK_URL: the URL of the webhook (as copied from n8n)
# - WEBHOOK_USERNAME: the username to use when auth'ing to the webhook
# - WEBHOOK_PASSWORD: the password to use when auth'ing to the webhook
# - (optional) ACTIVITYWATCH_URL: the URL to use when pulling ActivityWatch data (default: http://localhost:5600)
# - (optional) ACTIVITYWATCH_DAYS_AGO: how many days ago to pull data from ActivityWatch for (default: 20)

set -euo pipefail
script_dirpath="$(cd "$(dirname "${0}")" && pwd)"

env_filepath="${HOME}/.load-screentime-data.env"
if [ -f "${env_filepath}" ]; then
    source "${env_filepath}"
fi

if [ -z "${WEBHOOK_URL}" ]; then
    echo "Error: WEBHOOK_URL must be specified" >&2
    exit 1
fi
if [ -z "${WEBHOOK_USERNAME}" ]; then
    echo "Error: WEBHOOK_USERNAME must be specified" >&2
    exit 1
fi
if [ -z "${WEBHOOK_PASSWORD}" ]; then
    echo "Error: WEBHOOK_PASSWORD must be specified" >&2
    exit 1
fi

ACTIVITYWATCH_URL="${ACTIVITYWATCH_URL:-http://localhost:5600}"
ACTIVITYWATCH_DAYS_AGO="${ACTIVITYWATCH_DAYS_AGO:-20}"

END_TIME="2999-12-31"

start_time="$(date -v "-${ACTIVITYWATCH_DAYS_AGO}d" +%Y-%m-%d)"
time_period="${start_time}/${END_TIME}"

run_query() {
  local payload=$1
  curl -s -X POST "${ACTIVITYWATCH_URL}/api/0/query/" \
       -H 'Content-Type: application/json' \
       -d "$payload"
}

# Gets screentime by:
# - Grabbing non-AFK times
# - Filtering out times when Lookaway or loginwindow was active
# # Functions defined here: https://github.com/ActivityWatch/aw-server-rust/blob/master/aw-query/src/functions.rs
# Note that we don't use the "flood" function because it seems to create duplicate records
not_afk_query=$(cat <<EOF
{
  "timeperiods": ["${time_period}"],
  "query": [
    "afk_watcher_events = query_bucket(find_bucket(\\"aw-watcher-afk_\\"));",
    "at_keyboard_afk_watcher_events = filter_keyvals(afk_watcher_events, \\"status\\", [\\"not-afk\\"]);",
    "window_events = query_bucket(find_bucket(\\"aw-watcher-window_\\"));",
    "at_keyboard_window_events = exclude_keyvals(window_events, \\"app\\", [\\"LookAway\\", \\"loginwindow\\"]);",
    "RETURN = filter_period_intersect(at_keyboard_afk_watcher_events, at_keyboard_afk_watcher_events);"
  ],
  "name": "not-afk-${time_period}",
  "cache": false
}
EOF
)

# run_query "$afk_query" | jq . > aw_not_afk.json
data="$(run_query "${not_afk_query}" | jq -c .[0])"  # For some reason this comes as an array nested in an array

curl -XPOST -H "Content-Type: application/json" -u "${WEBHOOK_USERNAME}:${WEBHOOK_PASSWORD}' "${WEBHOOK_URL}" -d "${data}"

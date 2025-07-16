ActivityWatch Screentime Webhook Loader
========================================
This repo contains a small script, `load-screentime-data.sh`, to pull your screentime data from an [ActivityWatch](https://activitywatch.net/) server running locally and POST it to a webhook using basic auth (which in my case is [n8n](https://n8n.io/), but could be anything).

Screentime is defined as any time in which you're not AFK, and not seeing the login screen or [LookAway](https://lookaway.app/).

It expects the following environment variables to be set:

- `WEBHOOK_URL`: the URL of the webhook (if using n8n, this can be copied directly from n8n)
- `WEBHOOK_USERNAME`: the username to use when auth'ing to the webhook
- `WEBHOOK_PASSWORD`: the password to use when auth'ing to the webhook
- (optional) `ACTIVITYWATCH_URL`: the URL to use when pulling ActivityWatch data (default: http://localhost:5600)
- (optional) `ACTIVITYWATCH_DAYS_AGO`: how many days ago to pull data from ActivityWatch for (default: 20)

If a `${HOME}/.load-screentime-data.env` file exists, it will be sourced before the script runs. You can put environment variable values there.

This repo also contains an `install-plist.sh` script which on MacOS will schedule `load-screentime-data.sh` to run every 6 hours.

### Usage
1. Clone this repo 
2. Create `${HOME}/.load-screentime-data.sh`
3. Run `load-screentime-data.sh` to test everything works
3. Run `install-plist.sh` to schedule recurring loading

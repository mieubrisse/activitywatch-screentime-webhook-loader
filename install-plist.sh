#!/usr/bin/env bash

# Idemoptently reinstalls the load-screentime-data.sh command

set -euo pipefail
script_dirpath="$(cd "$(dirname "${0}")" && pwd)"

load_script_filepath="${script_dirpath}/load-screentime-data.sh"

if ! [ -f "${load_script_filepath}" ]; then
    echo "Error: No load script found at: ${load_script_filepath}" >&2
    exit 1
fi

plist_title="LoadScreentimeData"
plist_filepath="${HOME}/Library/LaunchAgents/${plist_title}.plist"

# Doesn't currently do logging because we rely on the data staleness checks to catch any breaks in the pipeline
cat << EOF > "${plist_filepath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_title}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${load_script_filepath}</string>
    </array>

    <!-- Run every day at 00:00, 06:00, 12:00, 18:00 -->
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Hour</key><integer>0</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
    </array>
</dict>
</plist>
EOF

launchctl bootout gui/$(id -u) "${plist_filepath}" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "${plist_filepath}"

#!/bin/bash
set -e
/opt/windrose-runtime/python/bin/python3.12 -E -B /opt/windrose-first-run/install_publisher.py /mnt/server
mkdir -p /mnt/server/R5/Saved
config=/mnt/server/R5/ServerDescription.json
if [ -L "$config" ]; then
    echo 'Windrose server configuration must be a regular file.' >&2
    exit 1
fi
if [ ! -f "$config" ]; then
    umask 077
    cat > "$config" <<'WINDROSE_CONFIG'
{
  "Version": 1,
  "DeploymentId": "",
  "ServerDescription_Persistent": {
    "PersistentServerId": "",
    "InviteCode": "",
    "IsPasswordProtected": true,
    "Password": "",
    "ServerName": "Windrose",
    "WorldIslandId": "",
    "MaxPlayerCount": 4,
    "UserSelectedRegion": "",
    "P2pProxyAddress": "0.0.0.0",
    "UseDirectConnection": true,
    "DirectConnectionServerAddress": "",
    "DirectConnectionServerPort": 25562,
    "DirectConnectionProxyAddress": "0.0.0.0",
    "AutoLoadLatestBackupIfHasBroken": true,
    "CanLaunchMultipleServerInstances": false
  }
}
WINDROSE_CONFIG
fi

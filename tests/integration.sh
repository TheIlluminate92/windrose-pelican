#!/bin/bash
set -euo pipefail
root=$(mktemp -d)
name="windrose-ci-${RANDOM}"
image=${WINDROSE_TEST_IMAGE:-windrose-pelican:0.10.0.9-first-run}
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; sudo rm -rf -- "$root"' EXIT
diagnose() {
    sudo python3 - "$root" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
source = root / ".windrose-first-run/first-console.log"
data = source.read_bytes()[-2 * 1024 * 1024:] if source.is_file() else b""
config = json.loads((root / "R5/ServerDescription.json").read_text())["ServerDescription_Persistent"]
saves = root / "R5/Saved/SaveProfiles/Default"
print(json.dumps({
    "gameplay_marker": b"Load map complete /Game/Maps/GYM/Genlandia/GenlandiaMulty" in data,
    "lobby_marker": b"Load map complete /Game/Maps/Lobby/R5ServerLobby" in data,
    "read_only_error": b"Read-only file system" in data,
    "permissions_error": b"Permission denied" in data,
    "backup_error": b"Save backup finished with error" in data,
    "backup_requested": b"Save backup requested" in data,
    "world_selected": bool(config.get("WorldIslandId")),
    "latest_zip_count": sum(1 for _ in saves.glob("**/*_Latest.zip")),
}, sort_keys=True))
PY
}
mkdir -p "$root/R5/Saved"
cp tests/server-description.json "$root/R5/ServerDescription.json"
if [ "${WINDROSE_TEST_FETCH:-0}" = 1 ]; then
    docker run --rm --mount "type=bind,src=$root,dst=/mnt/server" \
      --mount "type=bind,src=$PWD/install.sh,dst=/mnt/install/install.sh,readonly" \
      "$image" bash /mnt/install/install.sh
fi
sudo chown -R 99:100 "$root"
docker run --detach --tty --name "$name" --network none --read-only --user 99:100 \
  --cap-drop ALL --security-opt no-new-privileges --tmpfs /tmp:rw,exec,nosuid,size=128m \
  --mount "type=bind,src=$root,dst=/home/container" \
  -e 'WORLD_NAME=CI First World' -e WORLD_PRESET_TYPE=Hard "$image"
for _ in $(seq 1 180); do
    test "$(docker inspect -f '{{.State.Running}}' "$name")" = true || {
        docker logs "$name" 2>&1 | grep -E 'Windrose first|Traceback|Error' | tail -n 12 || true
        diagnose
        exit 1
    }
    if docker logs "$name" 2>&1 | grep -F 'Windrose first-world settings verified.' >/dev/null; then
        sudo test -s "$root/.windrose-first-run/complete.json"
        sudo test -s "$root/.windrose-first-run/previous-latest.zip"
        sudo test -d "$root/.windrose-first-run/previous-runtime"
        docker logs "$name" 2>&1 | grep -F 'LogGlobalStatus: LoadMap Load map complete /Game/Maps/GYM/Genlandia/GenlandiaMulty' >/dev/null
        echo "Verified first-run world settings and gameplay readiness."
        exit 0
    fi
    sleep 2
done
echo "Timed out waiting for verified world settings."
docker logs "$name" 2>&1 | grep -E 'Windrose first|Traceback|Error' | tail -n 12 || true
diagnose
exit 1

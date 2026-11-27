#!/bin/bash
set -euo pipefail
root=$(mktemp -d)
name="windrose-ci-${RANDOM}"
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; sudo rm -rf -- "$root"' EXIT
mkdir -p "$root/R5/Saved"
cp tests/server-description.json "$root/R5/ServerDescription.json"
sudo chown -R 99:100 "$root"
docker run --detach --name "$name" --network none --read-only --user 99:100 \
  --cap-drop ALL --security-opt no-new-privileges --tmpfs /tmp:rw,exec,nosuid,size=128m \
  --mount "type=bind,src=$root,dst=/home/container" \
  -e 'WORLD_NAME=CI First World' -e WORLD_PRESET_TYPE=Hard windrose-pelican:0.10.0.9-first-run
for _ in $(seq 1 180); do
    test "$(docker inspect -f '{{.State.Running}}' "$name")" = true || {
        docker logs "$name" 2>&1 | grep -E 'Windrose first|Traceback|Error' | tail -n 12 || true
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
exit 1

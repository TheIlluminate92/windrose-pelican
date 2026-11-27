import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from native_first_run import READY

ROOT = Path(__file__).resolve().parents[1]
WORLD = "AABBCCDDEEFF00112233445566778899"
MOCK = r'''#!/usr/bin/env python3
import json
import os
import signal
import sys
import time
from pathlib import Path
from zipfile import ZipFile

world = "AABBCCDDEEFF00112233445566778899"
config = Path("R5/ServerDescription.json")
data = json.loads(config.read_text())
server = data["ServerDescription_Persistent"]
save = Path("R5/Saved/SaveProfiles/Default")
runtime = save / "RocksDB_v2/0.10.0/Worlds" / world
backup = save / "RocksDB_v2_Backups/Worlds" / world / (world + "_0.10.0_Latest.zip")
member = "AdditionalRecordFiles/WorldDescription.json"
marker = "LogGlobalStatus: LoadMap Load map complete /Game/Maps/GYM/Genlandia/GenlandiaMulty"
with Path("boots").open("a") as f:
    f.write("game\n")
if not server["WorldIslandId"]:
    assert server["DirectConnectionServerPort"] > 49151
    assert len(server["Password"]) == 24 and server["Password"] != "owner-only"
    def stop(*_):
        print("LogExit: Exiting.", flush=True)
        sys.exit(139 if not os.environ.get("BAD_STOP") else 3)
    signal.signal(signal.SIGINT, stop)
    server["WorldIslandId"] = world
    config.write_text(json.dumps(data))
    document = {"Version": 1, "WorldDescription": {"islandId": world, "CreationTime": 639109024009110020,
                "WorldName": "Default", "WorldPresetType": "Medium", "WorldSettings": {}}}
    runtime.mkdir(parents=True)
    backup.parent.mkdir(parents=True)
    (runtime/"WorldDescription.json").write_text(json.dumps(document))
    with ZipFile(backup,"w") as z:
        z.writestr(member,json.dumps(document))
        z.writestr("checkpoint/OPTIONS-0005","native checkpoint")
    print(marker,flush=True)
    while True:
        time.sleep(.1)
assert server["Password"] == "owner-only" and server["DirectConnectionServerPort"] == 25562
if not runtime.is_dir():
    runtime.mkdir(parents=True)
    with ZipFile(backup) as z:
        document = json.loads(z.read(member))
    if os.environ.get("BAD_RESTORE"):
        document["WorldDescription"]["WorldName"] = "Fallback"
    (runtime/"WorldDescription.json").write_text(json.dumps(document))
if os.environ.get("FILE_ONLY_RESTORE"):
    log = Path("R5/Saved/Logs/R5.log")
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(marker + "\n")
    time.sleep(1.5)
else:
    print(marker,flush=True)
'''
RUNNER = """
import sys
import native_first_run as startup
startup.GAME=sys.argv[1]
try:
    code=startup.main()
except (ValueError, OSError) as e:
    print(e,file=sys.stderr)
    code=1
raise SystemExit(code)
"""


class FirstRun(unittest.TestCase):
    def setUp(self):
        fixture = tempfile.TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        (self.root/"R5").mkdir()
        self.config = self.root/"R5/ServerDescription.json"
        self.config.write_text(json.dumps({"ServerDescription_Persistent":{
            "WorldIslandId":"", "UseDirectConnection":True, "DirectConnectionServerPort":25562,
            "IsPasswordProtected":True, "Password":"owner-only", "InviteCode":"original",
            "AutoLoadLatestBackupIfHasBroken":True,
        }}))
        self.game = self.root/"windrose"
        self.game.write_text(MOCK)
        self.game.chmod(0o755)
        self.state = self.root/".windrose-first-run"
        self.world = self.root/"R5/Saved/SaveProfiles/Default/RocksDB_v2/0.10.0/Worlds"/WORLD/"WorldDescription.json"

    def run_egg(self, **flags):
        env = os.environ | {"PYTHONPATH": str(ROOT), "WORLD_NAME": 'Crew "Test"', "WORLD_PRESET_TYPE": "Hard"} | flags
        return subprocess.run([sys.executable, "-c", RUNNER, str(self.game)], cwd=self.root, env=env,
                              capture_output=True, timeout=9)

    def test_full_first_boot_and_subsequent_start(self):
        finished = self.run_egg()
        self.assertEqual(finished.returncode, 0, finished.stderr)
        self.assertEqual(finished.stdout.count(READY), 1)
        self.assertLess(finished.stdout.index(b"settings verified"), finished.stdout.index(READY))
        self.assertEqual((self.root/"boots").read_text().splitlines(), ["game", "game"])
        self.assertTrue((self.state/"previous-runtime").is_dir())
        self.assertTrue((self.state/"previous-latest.zip").is_file())
        self.assertTrue((self.state/"complete.json").is_file())
        initial = self.world.read_bytes()
        self.assertEqual(json.loads(initial)["WorldDescription"]["WorldPresetType"], "Hard")
        self.assertEqual(self.run_egg(WORLD_PRESET_TYPE="Easy").returncode, 0)
        self.assertEqual(self.world.read_bytes(), initial)

    def test_second_boot_can_report_readiness_in_its_own_log(self):
        finished = self.run_egg(FILE_ONLY_RESTORE="1")
        self.assertEqual(finished.returncode, 0, finished.stderr)
        self.assertLess(finished.stdout.index(b"settings verified"), finished.stdout.index(READY))
        self.assertTrue((self.state/"complete.json").is_file())

    def test_unexpected_exit_holds(self):
        failed = self.run_egg(BAD_STOP="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertNotIn(READY, failed.stdout)
        self.assertFalse((self.state/"previous-runtime").exists())
        self.assertNotEqual(self.run_egg().returncode, 0)
        self.assertEqual((self.root/"boots").read_text().splitlines(), ["game"])

    def test_wrong_restore_does_not_announce_ready(self):
        failed = self.run_egg(BAD_RESTORE="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertNotIn(READY, failed.stdout)
        self.assertTrue((self.state/"previous-runtime").is_dir())
        self.assertFalse((self.state/"complete.json").exists())

    def test_32_character_password_is_rejected_before_launch(self):
        config = json.loads(self.config.read_text())
        config["ServerDescription_Persistent"]["Password"] = "x" * 32
        self.config.write_text(json.dumps(config))
        failed = self.run_egg()
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn(b"shorter than 32 characters", failed.stderr)
        self.assertFalse((self.root/"boots").exists())

    def test_recovery_disabled_stops_before_game_launch(self):
        config = json.loads(self.config.read_text())
        config["ServerDescription_Persistent"]["AutoLoadLatestBackupIfHasBroken"] = False
        self.config.write_text(json.dumps(config))
        failed = self.run_egg()
        self.assertNotEqual(failed.returncode, 0)
        self.assertFalse((self.root/"boots").exists())
        self.assertFalse((self.state/"pending.json").exists())


if __name__ == "__main__":
    unittest.main()

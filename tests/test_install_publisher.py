import io
import tarfile
import tempfile
import unittest
from pathlib import Path
from install_publisher import BINARY, PREFIX, extract_game


class Installer(unittest.TestCase):
    def test_extracts_publisher_and_owns_only_volumed_settings(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive = root / "layer.tar.gz"
            out = root / "game"
            out.mkdir()
            with tarfile.open(archive,"w:gz") as package:
                for name, data, mode in (
                    (PREFIX + BINARY, b"publisher executable", 0o755),
                    (PREFIX + "R5/ServerDescription.json", b"publisher example", 0o644),
                    (PREFIX + "R5/Saved/example", b"publisher example", 0o644),
                    ("outside", b"ignore", 0o644),
                ):
                    member=tarfile.TarInfo(name)
                    member.mode=mode
                    member.size=len(data)
                    package.addfile(member,io.BytesIO(data))
            extract_game(archive,out)
            self.assertEqual((out/BINARY).read_bytes(),b"publisher executable")
            self.assertEqual((out/"R5/Saved").readlink(),Path("../../R5/Saved"))
            self.assertEqual((out/"R5/ServerDescription.json").readlink(),Path("../../R5/ServerDescription.json"))
            self.assertFalse((out/"outside").exists())

    def test_rejects_links_from_publisher_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            archive=root/"layer.tar.gz"
            with tarfile.open(archive,"w:gz") as package:
                member=tarfile.TarInfo(PREFIX + "invalid")
                member.type=tarfile.SYMTYPE
                member.linkname="/"
                package.addfile(member)
            with self.assertRaises(ValueError):
                extract_game(archive,root/"game")

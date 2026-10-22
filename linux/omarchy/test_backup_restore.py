#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pytest==9.1.1"]
# ///
"""Prove encrypted backup and staging restore with fixtures, never real home data."""

import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path

import pytest

HERE = Path(__file__).resolve().parent
REAL_RESTIC = shutil.which("restic")
REAL_UV = os.environ.get("UV", shutil.which("uv"))
type Machine = tuple[Path, dict[str, str]]
FAKE_COMMANDS = r"""
import datetime, json, os, pathlib, shutil, subprocess, sys
command, *args = sys.argv[1:]
home = pathlib.Path.home()
with (home / "calls.jsonl").open("a") as log:
    log.write(json.dumps([command, *args]) + "\n")
if command == "sudo":
    expected = ["-n", "/usr/bin/tar", "--acls", "--xattrs", "--one-file-system",
                "-C", "/", "-cf", "-", "etc", "var/lib/tailscale"]
    assert args == expected, args
    sys.stdout.buffer.write(pathlib.Path(os.environ["TEST_ARCHIVE"]).read_bytes())
    sys.exit(8 if os.environ.get("FAIL_PRODUCER") else 0)
if command == "notify-send":
    sys.exit(0)
if command in {"ssh", "rsync", "systemctl", "ollama"}:
    sys.exit(95)
if command == "tee":
    rows = (home / "calls.jsonl").read_text().splitlines()
    count = sum(json.loads(line)[0] == "tee" for line in rows)
    if os.environ.get("FAIL_TEE") or str(count) == os.environ.get("FAIL_TEE_AT"):
        sys.exit(9)
    os.execv("/usr/bin/tee", ["tee", *args])
if command == "uv":
    assert args[:6] == ["run", "--no-project", "--python", "3.12", "python", "-c"]
    os.execv(sys.executable, [sys.executable, *args[5:]])
if args[0] == os.environ.get("FAIL_RESTIC"):
    sys.exit(6)
if args[0] == "backup":
    if "--stdin-from-command" in args:
        result = subprocess.run(args[args.index("--") + 1:], stdout=subprocess.DEVNULL)
        if result.returncode:
            sys.exit(result.returncode)
        (home / "machine-backed-up").touch()
    else:
        (home / "home-backed-up").touch()
elif args[0] == "snapshots":
    tag = args[args.index("--tag") + 1] if "--tag" in args else "legacy"
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    if os.environ.get("STALE_TAG") == tag:
        now = "2001-01-01T00:00:00+00:00"
    if os.environ.get("MISSING_TAG") == tag:
        snapshots = []
    else:
        newest = "a" if tag == "home-state" else "b"
        snapshots = [{"id": newest * 64, "time": now},
                     {"id": "c" * 64, "time": "2000-01-01T00:00:00+00:00"}]
    print(json.dumps(snapshots))
elif args[0] == "restore":
    assert "--verify" in args
    target = pathlib.Path(args[args.index("--target") + 1])
    target.mkdir(parents=True, exist_ok=True)
    if args[1] == "b" * 64:
        if os.environ.get("CORRUPT_ARCHIVE"):
            (target / "machine-state.tar").write_text("invalid archive fixture\n")
        elif not os.environ.get("MISSING_ARCHIVE"):
            shutil.copyfile(os.environ["TEST_ARCHIVE"], target / "machine-state.tar")
    else:
        path = target / "home/fixture/.ssh/config"
        path.parent.mkdir(parents=True)
        path.write_text("Host fixture\n")
"""


def system_archive(tmp_path: Path) -> Path:
    """Create a real archive of tiny nonsecret system-state fixtures."""
    root = tmp_path / "root"
    (root / "etc").mkdir(parents=True)
    (root / "etc/fixture.conf").write_text("fixture-system\n")
    (root / "etc/fixture.conf").chmod(0o640)
    (root / "etc/link.conf").symlink_to("fixture.conf")
    (root / "var/lib/tailscale").mkdir(parents=True)
    (root / "var/lib/tailscale/fixture.state").write_text("fixture-identity\n")
    archive = tmp_path / "fixture.tar"
    subprocess.run(
        [
            "/usr/bin/tar",
            "--acls",
            "--xattrs",
            "-cf",
            str(archive),
            "-C",
            str(root),
            "etc",
            "var/lib/tailscale",
        ],
        check=True,
    )
    return archive


@pytest.fixture
def machine(tmp_path: Path) -> Machine:
    """Prepare fake credentials, privileged producer and isolated command tracing."""
    home = tmp_path / "home"
    tools = home / ".local/bin"
    tools.mkdir(parents=True)
    config = home / ".config/restic"
    config.mkdir(parents=True)
    (config / "env").write_text("# Fixture repository configuration only.\n")
    (config / "excludes.txt").write_text("$HOME/helm/skip-me\n")
    (home / ".ssh").mkdir(mode=0o700)
    (home / ".ssh/config").write_text("Host fixture\n")
    (home / ".ssh/config").chmod(0o600)
    (home / ".config/app").mkdir()
    (home / ".config/app/settings").write_text("fixture-setting\n")
    (home / ".config/app/link").symlink_to("settings")
    (home / "helm").mkdir()
    (home / "helm/skip-me").write_text("exclude fixture\n")
    archive = system_archive(tmp_path)
    (home / "fake_commands.py").write_text(FAKE_COMMANDS)
    for command in (
        "restic",
        "sudo",
        "notify-send",
        "tee",
        "ssh",
        "rsync",
        "systemctl",
        "ollama",
        "uv",
    ):
        path = tools / command
        path.write_text(
            f'#!/bin/bash\nexec "$TEST_PYTHON" "$HOME/fake_commands.py" "{command}" "$@"\n'
        )
        path.chmod(0o755)
    (tools / "python3").symlink_to(sys.executable)
    env = {key: value for key, value in os.environ.items() if not key.startswith("RESTIC_")}
    env.update(
        HOME=str(home),
        PATH=f"{tools}:/usr/bin:/bin",
        TEST_ARCHIVE=str(archive),
        TEST_PYTHON=sys.executable,
        NO_LOCK="0",
        UV_OFFLINE="1",
        UV_CACHE_DIR=str(Path.home() / ".cache/uv"),
        UV_PYTHON_INSTALL_DIR=str(Path.home() / ".local/share/uv/python"),
    )
    return home, env


def run_script(name: str, env: dict[str, str], *args: str) -> subprocess.CompletedProcess[str]:
    """Run only the sandbox runtime script with a bounded timeout."""
    return subprocess.run(
        ["bash", str(HERE / name), *args], env=env, capture_output=True, text=True, timeout=60
    )


def calls(home: Path, command: str = "restic") -> list[list[str]]:
    """Return traced fake command arguments."""
    path = home / "calls.jsonl"
    return (
        [
            entry[1:]
            for line in path.read_text().splitlines()
            if (entry := json.loads(line))[0] == command
        ]
        if path.exists()
        else []
    )


def test_home_and_machine_sources_are_both_backed_up(machine: Machine) -> None:
    home, env = machine
    result = run_script("backup-drive", env)
    assert result.returncode == 0, result.stdout + result.stderr
    backups = [entry for entry in calls(home) if entry[0] == "backup"]
    assert str(home / ".ssh") in backups[0]
    assert str(home / ".config") in backups[0]
    assert "home-state" in backups[0]
    assert len(backups) == 2
    assert "machine-state" in backups[1]
    assert (home / "machine-backed-up").exists()
    assert calls(home, "sudo")


@pytest.mark.parametrize("failure", ["FAIL_PRODUCER", "FAIL_TEE"])
def test_producer_or_logging_failure_prevents_prune_and_success(
    machine: Machine, failure: str
) -> None:
    home, env = machine
    result = run_script("backup-drive", {**env, failure: "1"})
    assert result.returncode != 0
    assert not any(entry[0] == "forget" for entry in calls(home))
    assert " OK" not in (home / ".local/state/backup-drive/status").read_text()


@pytest.mark.parametrize("tee_number", [2, 4, 5, 7])
def test_each_backup_pipeline_detects_tee_failure(machine: Machine, tee_number: int) -> None:
    home, env = machine
    result = run_script("backup-drive", {**env, "FAIL_TEE_AT": str(tee_number)})
    assert result.returncode != 0
    assert " OK" not in (home / ".local/state/backup-drive/status").read_text()
    if tee_number < 7:
        assert not any(entry[0] == "forget" for entry in calls(home))


@pytest.mark.parametrize("tag", ["home-state", "machine-state"])
def test_each_snapshot_kind_requires_freshness(machine: Machine, tag: str) -> None:
    home, env = machine
    result = run_script("backup-drive", {**env, "STALE_TAG": tag})
    assert result.returncode != 0
    assert not any(entry[0] == "forget" for entry in calls(home))


@pytest.mark.parametrize("command", ["snapshots", "check", "forget"])
def test_failed_repository_command_never_reports_success(machine: Machine, command: str) -> None:
    home, env = machine
    result = run_script("backup-drive", {**env, "FAIL_RESTIC": command})
    assert result.returncode != 0
    assert " OK" not in (home / ".local/state/backup-drive/status").read_text()


def test_restore_uses_newest_tagged_ids_and_preserves_original_paths(machine: Machine) -> None:
    home, env = machine
    target = home.parent / "restore"
    result = run_script("restore-backup.sh", env, "--target", str(target))
    assert result.returncode == 0, result.stdout + result.stderr
    restores = [entry for entry in calls(home) if entry[0] == "restore"]
    assert [entry[1] for entry in restores] == ["a" * 64, "b" * 64]
    assert (target / "home/home/fixture/.ssh/config").read_text() == "Host fixture\n"
    assert (target / "system/etc/fixture.conf").read_text() == "fixture-system\n"
    assert stat.S_IMODE(target.stat().st_mode) == 0o700
    assert not calls(home, "sudo")


def test_explicit_legacy_home_snapshot_is_supported(machine: Machine) -> None:
    home, env = machine
    result = run_script(
        "restore-backup.sh",
        env,
        "--target",
        str(home.parent / "restore"),
        "--home-snapshot",
        "d" * 64,
        "--machine-snapshot",
        "b" * 64,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert not any(entry[0] == "snapshots" for entry in calls(home))
    assert [entry[1] for entry in calls(home) if entry[0] == "restore"] == ["d" * 64, "b" * 64]


@pytest.mark.parametrize(
    "kind",
    ["existing", "symlink", "dangling", "alias", "home", "root", "relative", "symlink-parent"],
)
def test_unsafe_restore_targets_are_rejected_without_repository_access(
    machine: Machine, kind: str
) -> None:
    home, env = machine
    target = home.parent / "restore"
    if kind == "existing":
        target.mkdir()
    elif kind in {"symlink", "dangling"}:
        target.symlink_to(home if kind == "symlink" else home / "missing")
    elif kind == "alias":
        target = home.parent / "new/../home"
    elif kind == "home":
        target = home
    elif kind == "root":
        target = Path("/")
    elif kind == "relative":
        target = Path("relative")
    else:
        (home.parent / "alias").symlink_to(home)
        target = home.parent / "alias/restore"
    result = run_script("restore-backup.sh", env, "--target", str(target))
    assert result.returncode != 0
    assert not calls(home), "unsafe target reached repository"
    assert (home / ".ssh/config").read_text() == "Host fixture\n"


@pytest.mark.parametrize(
    "failure", ["FAIL_RESTIC", "MISSING_ARCHIVE", "MISSING_TAG", "CORRUPT_ARCHIVE"]
)
def test_restore_failure_never_claims_success(machine: Machine, failure: str) -> None:
    home, env = machine
    value = "restore" if failure == "FAIL_RESTIC" else "machine-state"
    result = run_script(
        "restore-backup.sh", {**env, failure: value}, "--target", str(home.parent / "restore")
    )
    assert result.returncode != 0
    assert "restore OK" not in result.stdout


def test_excludes_and_install_declarations_are_rebuildable() -> None:
    excludes = (HERE / "restic-excludes.txt").read_text()
    assert "/home/abdullah" not in excludes
    assert "$HOME/work/mirsad/bundle" in excludes
    assert "$HOME/.local/state/rai/runtime" in excludes
    assert "$HOME/.config/Code/Cache" in excludes
    install = (HERE / "install.sh").read_text()
    assert '"$HERE/restic-excludes.txt"' in install
    assert '"$HOME/.config/restic/excludes.txt"' in install
    packages = (HERE / "packages/pacman.txt").read_text().splitlines()
    assert "restic" in packages
    assert "rclone" in packages


def test_real_local_encrypted_repository_roundtrip(machine: Machine) -> None:
    home, env = machine
    assert REAL_RESTIC, "installed restic is required for local encrypted proof"
    (home / ".local/bin/restic").unlink()
    (home / ".local/bin/restic").symlink_to(REAL_RESTIC)
    assert REAL_UV, "uv is required for the local fixture metadata parsing"
    (home / ".local/bin/uv").unlink()
    (home / ".local/bin/uv").symlink_to(REAL_UV)
    env.update(
        RESTIC_REPOSITORY=str(home.parent / "encrypted-repository"),
        RESTIC_PASSWORD="fixture-only-test-passphrase",
        RESTIC_CACHE_DIR=str(home.parent / "cache"),
    )
    initialized = subprocess.run(
        [REAL_RESTIC, "init"], env=env, capture_output=True, text=True, timeout=30
    )
    assert initialized.returncode == 0, initialized.stderr
    backed_up = run_script("backup-drive", env)
    assert backed_up.returncode == 0, backed_up.stdout + backed_up.stderr
    target = home.parent / "restore"
    restored = run_script("restore-backup.sh", env, "--target", str(target))
    assert restored.returncode == 0, restored.stdout + restored.stderr
    restored_home = target / "home" / home.relative_to("/")
    assert (restored_home / ".ssh/config").read_bytes() == (home / ".ssh/config").read_bytes()
    assert stat.S_IMODE((restored_home / ".ssh/config").stat().st_mode) == 0o600
    assert (restored_home / ".config/app/settings").read_text() == "fixture-setting\n"
    assert os.readlink(restored_home / ".config/app/link") == "settings"
    assert not (restored_home / "helm/skip-me").exists()
    assert (target / "system/etc/fixture.conf").read_text() == "fixture-system\n"
    assert stat.S_IMODE((target / "system/etc/fixture.conf").stat().st_mode) == 0o640
    assert os.readlink(target / "system/etc/link.conf") == "fixture.conf"
    assert (target / "system/var/lib/tailscale/fixture.state").read_text() == "fixture-identity\n"
    failed = run_script("backup-drive", {**env, "FAIL_PRODUCER": "1"})
    assert failed.returncode != 0
    snapshots = subprocess.run(
        [REAL_RESTIC, "snapshots", "--tag", "machine-state", "--json"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
        timeout=30,
    )
    assert len(json.loads(snapshots.stdout)) == 1, "failed producer created an archive snapshot"


if __name__ == "__main__":
    raise SystemExit(
        pytest.main(
            [
                __file__,
                "-v",
                "-p",
                "no:cacheprovider",
                f"--basetemp={Path.home()}/.cache/rai-backup-lock/rebuild-tests",
                *sys.argv[1:],
            ]
        )
    )

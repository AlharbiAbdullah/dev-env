#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pytest==9.1.1"]
# ///
"""Exercise backup and coordinator exclusion without real jobs or credentials."""

import os
import signal
import subprocess
import sys
import time
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest

BACKUP = Path(__file__).with_name("backup-drive")
MAINTENANCE = (
    Path(__file__).resolve().parents[3]
    / "helm/03-rai/skills/rai/scheduled/run-maintenance-ubuntu.sh"
)
GATE = """
touch "$HOME/$RUN_ID.enter"
while [ ! -e "$HOME/$RUN_ID.release" ]; do sleep 0.02; done
"""
type Sandbox = tuple[Path, list[subprocess.Popen[bytes]]]


def wait_for(predicate: Callable[[], bool], timeout: float = 4) -> None:
    """Wait for a bounded subprocess condition, failing on timeout."""
    deadline = time.monotonic() + timeout
    while not predicate():
        assert time.monotonic() < deadline, "subprocess condition timed out"
        time.sleep(0.01)


@pytest.fixture
def sandbox(tmp_path: Path) -> Iterator[Sandbox]:
    """Create a fake home and kill every process group on teardown."""
    tools = tmp_path / ".local/bin"
    tools.mkdir(parents=True)
    config = tmp_path / ".config/restic"
    config.mkdir(parents=True)
    (config / "env").write_text("# No credentials: external commands are stubs.\n")
    (config / "excludes.txt").touch()
    (tmp_path / "helm").mkdir()
    stubs = {
        # Maintenance asks machine.py for its role first; the hub is the producer.
        "uv": '#!/bin/bash\n[ "${*: -1}" != role ] || { echo producer; exit 0; }\n'
        + 'while [ $# -gt 0 ] && [ "$1" != python ]; do shift; done\n'
        + '[ $# -gt 0 ] || exit 64\nshift\nexec python3 "$@"\n',
        "restic": '#!/bin/bash\nif [ "$1" = "${BLOCK_STAGE:-backup}" ]; then\n'
        + GATE
        + '\nfi\n[ "$1" != "${FAIL_STAGE:-}" ] || exit 9\n'
        + 'if [ "$1" = snapshots ]; then echo "[]"; fi\n',
        "python3": "#!/bin/bash\ncat >/dev/null\ndate +%F\n",
        "notify-send": "#!/bin/bash\nexit 0\n",
    }
    for name, body in stubs.items():
        path = tools / name
        path.write_text(body)
        path.chmod(0o755)
    prefix = MAINTENANCE.read_text().split("# Job guard", 1)[0]
    (tmp_path / "maintenance.sh").write_text(prefix + GATE + '\nexit "${BODY_EXIT:-0}"\n')
    processes: list[subprocess.Popen[bytes]] = []
    yield tmp_path, processes
    for process in processes:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=4)


def start(sandbox: Sandbox, job: str, name: str, **settings: str) -> subprocess.Popen[bytes]:
    """Launch a sandbox job with stubbed external commands."""
    home, processes = sandbox
    script = BACKUP if job == "backup" else home / "maintenance.sh"
    env = {
        **os.environ,
        "HOME": str(home),
        "PATH": f"{home}/.local/bin:/usr/bin:/bin",
        "RUN_ID": name,
        "NO_LOCK": "0",
        **settings,
    }
    process = subprocess.Popen(
        ["bash", str(script)],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    processes.append(process)
    return process


def entered(home: Path, name: str) -> bool:
    """Return whether the harmless job body has begun."""
    return (home / f"{name}.enter").exists()


def release(home: Path, name: str) -> None:
    """Allow a harmless blocked body to finish."""
    (home / f"{name}.release").touch()


@pytest.mark.parametrize("stage", ["backup", "forget", "snapshots", "check"])
def test_backup_holds_lock_through_entire_job(sandbox: Sandbox, stage: str) -> None:
    home, _ = sandbox
    holder = start(sandbox, "backup", "holder", BLOCK_STAGE=stage)
    wait_for(lambda: entered(home, "holder"))
    contender = start(sandbox, "maintenance", "contender")
    wait_for(lambda: contender.poll() is not None or entered(home, "contender"))
    assert not entered(home, "contender"), "maintenance overlapped backup"
    assert contender.wait(timeout=4) == 0
    release(home, "holder")
    assert holder.wait(timeout=4) == 0


def test_backup_waits_for_maintenance_then_acquires(sandbox: Sandbox) -> None:
    home, _ = sandbox
    holder = start(sandbox, "maintenance", "holder")
    wait_for(lambda: entered(home, "holder"))
    contender = start(sandbox, "backup", "contender")
    time.sleep(0.2)
    assert not entered(home, "contender"), "backup overlapped maintenance"
    assert contender.poll() is None, "backup must wait, not skip"
    release(home, "holder")
    assert holder.wait(timeout=4) == 0
    wait_for(lambda: entered(home, "contender"))
    release(home, "contender")
    assert contender.wait(timeout=4) == 0
    assert (home / ".local/state/rai-maintenance/.run.lock").is_file()


def test_live_old_lock_is_never_evicted(sandbox: Sandbox) -> None:
    home, _ = sandbox
    holder = start(sandbox, "maintenance", "holder")
    wait_for(lambda: entered(home, "holder"))
    state = home / ".local/state/rai-maintenance"
    for lock in (state / ".lock", state / ".run.lock"):
        if lock.exists():
            os.utime(lock, (1, 1))
    contender = start(sandbox, "maintenance", "contender")
    wait_for(lambda: contender.poll() is not None or entered(home, "contender"))
    assert not entered(home, "contender"), "live holder was evicted by age"
    assert contender.wait(timeout=4) == 0
    assert holder.poll() is None


@pytest.mark.parametrize("job", ["backup", "maintenance"])
def test_abnormal_termination_releases_lock(sandbox: Sandbox, job: str) -> None:
    home, _ = sandbox
    holder = start(sandbox, job, "holder")
    wait_for(lambda: entered(home, "holder"))
    os.killpg(holder.pid, signal.SIGKILL)
    assert holder.wait(timeout=4) == -signal.SIGKILL
    contender = start(sandbox, "maintenance", "contender")
    wait_for(lambda: entered(home, "contender") or contender.poll() is not None)
    assert entered(home, "contender"), "dead holder prevented recovery"
    release(home, "contender")
    assert contender.wait(timeout=4) == 0


@pytest.mark.parametrize("job", ["backup", "maintenance"])
def test_failure_releases_lock(sandbox: Sandbox, job: str) -> None:
    home, _ = sandbox
    holder = start(sandbox, job, "holder", FAIL_STAGE="backup", BODY_EXIT="7")
    wait_for(lambda: entered(home, "holder"))
    release(home, "holder")
    assert holder.wait(timeout=4) != 0
    contender = start(sandbox, "maintenance", "contender")
    wait_for(lambda: entered(home, "contender"))
    release(home, "contender")
    assert contender.wait(timeout=4) == 0


@pytest.mark.parametrize(
    "jobs", [("backup", "backup"), ("maintenance", "maintenance"), ("backup", "maintenance")]
)
def test_simultaneous_contenders_cannot_overlap(sandbox: Sandbox, jobs: tuple[str, str]) -> None:
    home, _ = sandbox
    first = start(sandbox, jobs[0], "first")
    second = start(sandbox, jobs[1], "second")
    wait_for(lambda: entered(home, "first") or entered(home, "second"))
    time.sleep(0.2)
    assert entered(home, "first") != entered(home, "second"), "simultaneous jobs overlapped"
    release(home, "first")
    release(home, "second")
    assert first.wait(timeout=4) == 0
    assert second.wait(timeout=4) == 0


def test_no_lock_bypass_is_preserved(sandbox: Sandbox) -> None:
    home, _ = sandbox
    holder = start(sandbox, "backup", "holder")
    wait_for(lambda: entered(home, "holder"))
    contender = start(sandbox, "maintenance", "contender", NO_LOCK="1")
    wait_for(lambda: entered(home, "contender"))
    release(home, "contender")
    assert contender.wait(timeout=4) == 0
    assert holder.poll() is None


def test_waiting_backup_preserves_active_backup_log(sandbox: Sandbox) -> None:
    home, _ = sandbox
    holder = start(sandbox, "backup", "holder")
    wait_for(lambda: entered(home, "holder"))
    contender = start(sandbox, "backup", "contender")
    time.sleep(0.2)
    assert "backup start" in (home / ".local/state/backup-drive/last-run.log").read_text()
    assert contender.poll() is None
    assert holder.poll() is None


def test_child_retains_lock_after_parent_dies(sandbox: Sandbox) -> None:
    home, _ = sandbox
    holder = start(sandbox, "backup", "holder")
    wait_for(lambda: entered(home, "holder"))
    holder.kill()
    assert holder.wait(timeout=4) == -signal.SIGKILL
    contender = start(sandbox, "maintenance", "contender")
    wait_for(lambda: contender.poll() is not None or entered(home, "contender"))
    assert not entered(home, "contender"), "backup child lost its parent's lock"
    assert contender.wait(timeout=4) == 0
    os.killpg(holder.pid, signal.SIGKILL)
    retry = start(sandbox, "maintenance", "retry")
    wait_for(lambda: entered(home, "retry"))
    release(home, "retry")
    assert retry.wait(timeout=4) == 0


@pytest.mark.parametrize("job", ["backup", "maintenance"])
def test_lock_open_errors_fail(sandbox: Sandbox, job: str) -> None:
    home, _ = sandbox
    (home / ".local/state/rai-maintenance/.run.lock").mkdir(parents=True)
    process = start(sandbox, job, "broken")
    wait_for(lambda: process.poll() is not None or entered(home, "broken"))
    assert not entered(home, "broken"), "job ignored an unopenable lock"
    assert process.wait(timeout=4) != 0


@pytest.mark.parametrize("job", ["backup", "maintenance"])
def test_flock_errors_fail_instead_of_skipping(sandbox: Sandbox, job: str) -> None:
    home, _ = sandbox
    stub = home / ".local/bin/flock"
    stub.write_text("#!/bin/bash\nexit 71\n")
    stub.chmod(0o755)
    process = start(sandbox, job, "broken")
    wait_for(lambda: process.poll() is not None or entered(home, "broken"))
    assert not entered(home, "broken"), "job ignored flock error"
    assert process.wait(timeout=4) != 0


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v", "-p", "no:cacheprovider", *sys.argv[1:]]))

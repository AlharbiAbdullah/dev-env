#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pytest==9.1.1"]
# ///
"""install.sh refuses to provision a box until its machine role is named."""

import subprocess
import sys
from pathlib import Path

import pytest

INSTALL = Path(__file__).with_name("install.sh")
MARKER = "PAST-ROLE-GATE"


def run_role_gate(tmp_path: Path, role: str | None) -> subprocess.CompletedProcess[str]:
    """Run only the lines before the platform guard, so nothing is ever provisioned."""
    prefix = INSTALL.read_text().split("# --- guard", 1)[0]
    script = tmp_path / "gate.sh"
    script.write_text(prefix + f'echo "{MARKER} $MACHINE_ROLE $ENABLE_TIMERS"\n')
    env = {"HOME": str(tmp_path), "PATH": "/usr/bin:/bin"}
    if role is not None:
        env["RAI_ROLE"] = role
    return subprocess.run(["bash", str(script)], env=env, capture_output=True, text=True, timeout=10)


@pytest.mark.parametrize("role", [None, "", "hub"])
def test_a_missing_or_unknown_role_is_refused(tmp_path: Path, role: str | None) -> None:
    result = run_role_gate(tmp_path, role)
    assert result.returncode != 0
    assert MARKER not in result.stdout
    assert "RAI_ROLE=producer" in result.stdout + result.stderr


@pytest.mark.parametrize(("role", "timers"), [("producer", "1"), ("consumer", "0")])
def test_an_explicit_role_proceeds(tmp_path: Path, role: str, timers: str) -> None:
    result = run_role_gate(tmp_path, role)
    assert result.returncode == 0
    assert f"{MARKER} {role} {timers}" in result.stdout


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v", "-p", "no:cacheprovider", *sys.argv[1:]]))

#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest"]
# ///
"""Regression tests for agents-local's token counts. Run: ./test_agents_local.py"""

import importlib.machinery
import importlib.util
import json
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("agents-local")
NOW_ISO = datetime.now(timezone.utc).isoformat()
NOW_MS = int(datetime.now(timezone.utc).timestamp() * 1000)


@pytest.fixture
def agents(tmp_path, monkeypatch):
    """The collector, loaded fresh against an empty home and state folder."""
    monkeypatch.setenv("HOME", str(tmp_path))
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path / "state"))
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path / "data"))
    monkeypatch.setenv("CODEX_HOME", str(tmp_path / "codex"))
    loader = importlib.machinery.SourceFileLoader("agents_local", str(SCRIPT))
    spec = importlib.util.spec_from_loader("agents_local", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def write_jsonl(path, entries):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(entry) + "\n" for entry in entries))


def opencode_db(path: Path, messages: list[dict]) -> None:
    """Persist v2 message rows, with the type column separate from the JSON payload."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(path) as conn:
        conn.execute(
            "CREATE TABLE session_message (id TEXT PRIMARY KEY, session_id TEXT NOT NULL,"
            " type TEXT NOT NULL, seq INTEGER NOT NULL, time_created INTEGER NOT NULL,"
            " time_updated INTEGER NOT NULL, data TEXT NOT NULL)"
        )
        rows = [
            (f"msg_{index}", "ses_1", message.get("type", "assistant"), index, NOW_MS, NOW_MS,
             json.dumps({key: value for key, value in message.items() if key != "type"}))
            for index, message in enumerate(messages)
        ]
        conn.executemany("INSERT INTO session_message VALUES (?, ?, ?, ?, ?, ?, ?)", rows)


def week(stats):
    """Input, output, cache reads and cache writes over the week, summed across models."""
    rows = stats.recent_model_usage.values()
    fields = ("inputTokens", "outputTokens", "cacheReadInputTokens", "cacheCreationInputTokens")
    return tuple(sum(r[field] for r in rows) for field in fields)


def codex_usage(n):
    return {"input_tokens": n, "cached_input_tokens": 0, "output_tokens": 1, "total_tokens": n + 1}


def token_count(total, last):
    info = {"total_token_usage": codex_usage(total), "last_token_usage": codex_usage(last)}
    payload = {"type": "token_count", "info": info}
    return {"timestamp": NOW_ISO, "type": "event_msg", "payload": payload}


def test_codex_repeated_token_count_counts_once(agents, tmp_path):
    # Codex repeats a token_count event with an unchanged running total; it is one turn, not two.
    write_jsonl(tmp_path / "codex" / "sessions" / "rollout-a.jsonl", [
        {"timestamp": NOW_ISO, "type": "turn_context",
         "payload": {"model": "gpt-x", "effort": "high"}},
        token_count(100, 100),
        token_count(100, 100),
        token_count(150, 50),
    ])
    assert week(agents.scan_codex(effort=True)) == (150, 2, 0, 0)


def claude_line(output_tokens, block):
    usage = {"input_tokens": 10, "output_tokens": output_tokens,
             "cache_read_input_tokens": 5000, "cache_creation_input_tokens": 22}
    message = {"id": "msg_1", "role": "assistant", "model": "claude-x", "usage": usage,
               "content": [{"type": block}]}
    return {"timestamp": NOW_ISO, "requestId": "req_1", "effort": "high", "message": message}


def test_claude_reply_counts_once_at_its_final_usage(agents, tmp_path):
    # The thinking block's line carries a partial output count, the last block's the final one.
    # Cache reads and writes count, as on the Claude Code tab.
    write_jsonl(tmp_path / ".claude" / "projects" / "p" / "s.jsonl",
                [claude_line(4, "thinking"), claude_line(203, "text")])
    assert week(agents.scan_claude()) == (10, 203, 5000, 22)


def test_pi_counts_cache_reads_and_writes(agents, tmp_path):
    usage = {"input": 5, "output": 7, "cacheRead": 1000, "cacheWrite": 100}
    message = {"role": "assistant", "model": "m", "usage": usage}
    write_jsonl(tmp_path / ".pi" / "agent" / "sessions" / "s.jsonl",
                [{"type": "message", "id": "e1", "timestamp": NOW_ISO, "message": message}])
    assert week(agents.scan_pi(effort=True)) == (5, 7, 1000, 100)


def test_opencode_counts_council_voice_databases(agents, tmp_path):
    # Each /council voice keeps a private opencode database. Its tokens still count.
    tokens = {"input": 10, "output": 3, "reasoning": 0, "cache": {"read": 50, "write": 0}}
    message = {"model": {"id": "m", "variant": "high"},
               "time": {"created": NOW_MS}, "tokens": tokens}
    opencode_db(tmp_path / "data" / "opencode" / "opencode.db", [message])
    opencode_db(tmp_path / "state" / "rai" / "council" / "opencode" / "glm" / "data" / "opencode"
                / "opencode.db", [message])
    assert week(agents.scan_opencode(effort=True)) == (20, 6, 100, 0)


@pytest.mark.parametrize("effort, model_key", [(False, "gpt-x"), (True, "gpt-x (high)")])
def test_opencode_v2_assistant_tokens_and_effort(agents, tmp_path, effort, model_key):
    tokens = {"input": 10, "output": 3, "reasoning": 5, "cache": {"read": 50, "write": 7}}
    message = {"model": {"id": "openai/gpt-x", "variant": "high"},
               "time": {"created": NOW_MS}, "tokens": tokens}
    path = tmp_path / "data" / "opencode" / "opencode.db"
    opencode_db(path, [message, {**message, "type": "user"},
                       {**message, "type": "synthetic"}, {**message, "tokens": {}}])
    before = path.read_bytes()
    stats = agents.scan_opencode(effort=effort)
    assert week(stats) == (10, 8, 50, 7)
    assert stats.recent_model_usage == {
        model_key: {"inputTokens": 10, "outputTokens": 8, "cacheReadInputTokens": 50,
                    "cacheCreationInputTokens": 7},
    }
    assert stats.total_prompts == 1
    assert stats.today_sessions == {"opencode:ses_1"}
    assert path.read_bytes() == before


def test_opencode_v2_skips_malformed_assistant_payload(agents, tmp_path):
    message = {"model": {"id": "m"}, "time": {"created": NOW_MS}, "tokens": {"input": 4}}
    path = tmp_path / "data" / "opencode" / "opencode.db"
    opencode_db(path, [message, message, message])
    with sqlite3.connect(path) as conn:
        conn.execute("UPDATE session_message SET data = ? WHERE id = ?", ("{", "msg_1"))
        conn.execute("UPDATE session_message SET data = ? WHERE id = ?", ("[]", "msg_2"))
    assert week(agents.scan_opencode(effort=True)) == (4, 0, 0, 0)


def test_ai_record_counts_every_token(agents, tmp_path):
    # The AI tab uses the Claude Code tab's metric: cache reads and writes included.
    usage = {"input": 5, "output": 7, "cacheRead": 1000, "cacheWrite": 100}
    message = {"role": "assistant", "model": "m", "usage": usage}
    write_jsonl(tmp_path / ".pi" / "agent" / "sessions" / "s.jsonl",
                [{"type": "message", "id": "e1", "timestamp": NOW_ISO, "message": message}])
    assert agents.scan_ai()["todayTotalTokens"] == 1112


def test_ai_record_rebuilds_on_every_run(agents, tmp_path, monkeypatch):
    # The timer runs every five minutes. A record written a minute ago must not hide new tokens.
    agents.write_record(agents.AI_ID, {"id": agents.AI_ID, "todayTotalTokens": 0})
    write_jsonl(tmp_path / ".claude" / "projects" / "p" / "s.jsonl", [claude_line(203, "text")])
    monkeypatch.setattr(sys, "argv", ["agents-local", agents.AI_ID])
    assert agents.main() == 0
    record = json.loads((agents.USAGE_DIR / f"{agents.AI_ID}.json").read_text())
    assert record["todayTotalTokens"] > 0


def openai_window(resets_in_hours):
    reset = datetime.now(timezone.utc) + timedelta(hours=resets_in_hours)
    return {"label": "Weekly (7-day)", "title": "OpenAI week", "sub": "ChatGPT", "plan": "Prolite",
            "percent": 0.24, "resetsAt": reset.isoformat()}


def broken_codex(tmp_path, monkeypatch, agents):
    """A codex that dies before it answers, as the app server did when it hung."""
    fake = tmp_path / "codex"
    fake.write_text("#!/bin/sh\necho 'auth refresh failed' >&2\nexit 1\n")
    fake.chmod(0o755)
    monkeypatch.setattr(agents, "CODEX_BIN", str(fake))


def test_openai_read_failure_keeps_the_last_windows(agents, tmp_path, monkeypatch, capsys):
    # One failed read must not drop the OpenAI card; a window past its reset is no longer true.
    live, expired = openai_window(48), openai_window(-1)
    chatgpt = agents.SUBSCRIPTIONS["chatgpt"][0]
    agents.write_record(chatgpt, {"id": chatgpt, "limits": [live, expired]})
    broken_codex(tmp_path, monkeypatch, agents)
    assert agents.openai_limits() == [live]
    assert "auth refresh failed" in capsys.readouterr().err


def test_openai_read_failure_without_a_last_reading_is_empty(agents, tmp_path, monkeypatch):
    broken_codex(tmp_path, monkeypatch, agents)
    assert agents.openai_limits() == []


def test_console_go_windows_meter_share_and_dollars(agents):
    # The Go key endpoint rounds to whole percents, so the Console meters are the
    # only place a used day shows: 0.35% of $60 is $0.21.
    status = {"access": {"meters": {
        "fiveHour": {
            "limitMicroCents": "1200000000", "usedMicroCents": "7212881",
            "resetsAt": "2026-11-01T02:58:12.000Z",
        },
        "week": {
            "limitMicroCents": "3000000000", "usedMicroCents": "21236121",
            "resetsAt": "2026-11-02T00:00:00.000Z",
        },
        "month": {
            "limitMicroCents": "6000000000", "usedMicroCents": "21236121",
            "resetsAt": "2026-11-30T12:11:21.000Z",
        },
    }}}
    windows = agents.console_go_windows(status)
    assert [w["detail"] for w in windows] == ["$0.07 of $12.00", "$0.21 of $30.00", "$0.21 of $60.00"]
    assert [w["percent"] for w in windows] == pytest.approx([0.006010734167, 0.007078707, 0.0035393535])
    assert windows[0]["resetsAt"] == "2026-11-01T02:58:12.000Z"


def test_agy_keeps_general_gemini_week_and_argon_week_separate(agents, tmp_path, monkeypatch):
    # Google AI Pro splits Gemini 4 Argon into its own weekly group alongside Gemini Models;
    # the Gemini pool shows 5h, week (general) and Argon (like Fable on Claude).
    payload = {"command": {"name": "usage", "data": {"groups": [
        {"name": "Gemini Models", "buckets": [
            {"id": "gemini-weekly", "window": "weekly", "remaining_fraction": 0.9973,
             "reset_time": "2026-11-02T16:29:49Z"},
            {"id": "gemini-5h", "window": "5h", "remaining_fraction": 0.9970,
             "reset_time": "2026-10-27T11:36:23Z"},
        ]},
        {"name": "Claude and GPT models", "buckets": [
            {"id": "3p-weekly", "window": "weekly", "remaining_fraction": 0.5047,
             "reset_time": "2026-10-31T19:52:57Z"},
            {"id": "3p-5h", "window": "5h", "remaining_fraction": 1.0,
             "reset_time": "2026-10-27T14:13:57Z"},
        ]},
        {"name": "Gemini 4 Argon", "buckets": [
            {"id": "gemini-argon-wtu-weekly", "window": "weekly", "remaining_fraction": 0.7199,
             "reset_time": "2026-11-02T16:09:39Z"},
        ]},
    ]}}}
    fake = tmp_path / "agy"
    fake.write_text(f"#!/bin/sh\nprintf '%s\\n' '{json.dumps(payload)}'\n")
    fake.chmod(0o755)
    monkeypatch.setattr(agents, "AGY_BIN", str(fake))
    windows = agents.agy_limits()
    assert [(w["title"], w["percent"], w["resetsAt"]) for w in windows] == [
        ("Gemini 5h", 0.003, "2026-10-27T11:36:23Z"),
        ("Gemini week", 0.0027, "2026-11-02T16:29:49Z"),
        ("Gemini Argon", 0.2801, "2026-11-02T16:09:39Z"),
        ("Claude/GPT 5h", 0.0, ""),
        ("Claude/GPT week", 0.4953, "2026-10-31T19:52:57Z"),
    ]


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))


def test_one_pass_splits_each_message_onto_its_subscription(agents, tmp_path):
    # A tab is a subscription now: Go tokens land on OpenCode Go, ChatGPT's on
    # ChatGPT, and All still counts both.
    tokens = {"input": 10, "output": 3, "reasoning": 0, "cache": {"read": 50, "write": 0}}
    opencode_db(tmp_path / "data" / "opencode" / "opencode.db", [
        {"model": {"id": "deepseek-v4.1-flash", "providerID": "opencode-go"},
         "time": {"created": NOW_MS}, "tokens": tokens},
    ])
    message = {"role": "assistant", "model": "gpt-6.1-sol", "provider": "openai",
               "usage": {"input": 5, "output": 7}}
    write_jsonl(tmp_path / ".pi" / "agent" / "sessions" / "s.jsonl",
                [{"type": "message", "id": "e1", "timestamp": NOW_ISO, "message": message}])

    everything = agents.scan_everything()
    assert list(everything.subs["opencode-go"].recent_model_usage) == ["deepseek-v4.1-flash"]
    assert list(everything.subs["chatgpt"].recent_model_usage) == ["gpt-6.1-sol"]
    assert set(everything.model_usage) == {"deepseek-v4.1-flash", "gpt-6.1-sol"}

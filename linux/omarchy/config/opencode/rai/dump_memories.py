import sys, os
from pathlib import Path
from datetime import datetime, timedelta
# Faithful port of session-start.py load_memories(), with a char budget so the
# "full vault" load inside ~/helm can't overflow the model context window.
CHROMADB_PATH = Path.home()/"helm"/"03-rai"/"semantic-memory"/"chromadb"
DAYS = int(os.environ.get("RAI_MEM_DAYS", "7"))           # 0 = no date filter (full)
MAXCHARS = int(os.environ.get("RAI_MEM_MAXCHARS", "0"))   # 0 = no cap
try:
    import chromadb
    col = chromadb.PersistentClient(path=str(CHROMADB_PATH)).get_collection("memories")
    res = col.get(include=["metadatas", "documents"])
    docs = res.get("documents") or []
    mems = [{"doc": d, "meta": res["metadatas"][i]} for i, d in enumerate(docs)]
    mems.sort(key=lambda x: x["meta"].get("date", ""), reverse=True)  # newest first
    if DAYS > 0:
        cutoff = (datetime.now() - timedelta(days=DAYS)).strftime("%Y-%m-%d")
        mems = [m for m in mems if m["meta"].get("date", "") >= cutoff]
    lines, total = [], 0
    for m in mems:
        meta = m["meta"]; date = meta.get("date", "?"); ctx = meta.get("context", "") or meta.get("type", "")
        prefix = f"[{date}]" + (f" {ctx}:" if ctx else "")
        line = f"{prefix} {m['doc'].strip()}"
        if MAXCHARS and total + len(line) > MAXCHARS:
            break
        lines.append(line); total += len(line)
    scope = f"last {DAYS} days" if DAYS > 0 else f"most recent {len(lines)}"
    print(f"## Rai Memory ({scope} of {len(mems)} matched; older memories via /recall)\n")
    print("\n\n".join(lines))
except Exception as e:
    print(f"<!-- memory load failed: {e} -->", file=sys.stderr); sys.exit(1)

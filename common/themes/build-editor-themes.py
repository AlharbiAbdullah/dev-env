#!/usr/bin/env python3
"""
build-editor-themes.py — regenerate every editor theme and package them as one vsix.

Generates a VS Code color theme from each ~/.config/themes/<name>/theme.lua (see
vscode-theme-gen.py), bundles them into a single `rai.rai-themes` extension, and
installs it into Cursor, VS Code and Antigravity. One extension, every theme, so a palette
edit reaches the editor with one command instead of hunting for a published theme
that happens to match.

Usage:
  python3 build-editor-themes.py            # build + install
  python3 build-editor-themes.py --build    # build only, print the vsix path
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))

# Siblings in this directory are hyphen-named by convention, so load by path.
_spec = importlib.util.spec_from_file_location("gen", os.path.join(HERE, "vscode-theme-gen.py"))
_gen = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_gen)
build, read_theme = _gen.build, _gen.read_theme

PUB, NAME = "rai", "rai-themes"
# `code` on PATH may be the Cursor shim, so VS Code is addressed by absolute path.
EDITORS = [("cursor", os.path.expanduser("~/.cursor/extensions")),
           ("/usr/bin/code", os.path.expanduser("~/.vscode/extensions")),
           ("antigravity", os.path.expanduser("~/.antigravity-ide/extensions"))]

MANIFEST = """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{name}" Version="{ver}" Publisher="{pub}" />
    <DisplayName>Rai Themes</DisplayName>
    <Description>Editor themes generated from ~/.config/themes/*/theme.lua</Description>
    <Tags>theme,color-theme</Tags>
    <Categories>Themes</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.70.0" />
      <Property Id="Microsoft.VisualStudio.Code.ExtensionDependencies" Value="" />
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
  </Assets>
</PackageManifest>
"""

CONTENT_TYPES = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json" />
  <Default Extension="vsixmanifest" ContentType="text/xml" />
</Types>
"""


def theme_names():
    out = []
    for d in sorted(os.listdir(HERE)):
        if d.startswith("_") or d.startswith("."):
            continue
        if os.path.isfile(os.path.join(HERE, d, "theme.lua")):
            out.append(d)
    return out


def version(names):
    """Bump on any palette change so the editors reload rather than skip the install."""
    digest = 0
    for n in names:
        src = open(os.path.join(HERE, n, "theme.lua"), "rb").read()
        digest = (digest * 31 + sum(src)) % 100000
    return f"0.2.{digest}"


def make_vsix(names, out_path):
    import zipfile
    ver = version(names)
    themes, payload = [], {}
    for n in names:
        t = build(read_theme(n))
        fname = f"{n}.json"
        themes.append({
            "label": t["name"],
            "uiTheme": "vs-dark" if t["type"] == "dark" else "vs",
            "path": f"./themes/{fname}",
        })
        payload[f"extension/themes/{fname}"] = json.dumps(t, indent=2)

    payload["extension/package.json"] = json.dumps({
        "name": NAME,
        "displayName": "Rai Themes",
        "description": "Editor themes generated from ~/.config/themes/*/theme.lua",
        "version": ver,
        "publisher": PUB,
        "engines": {"vscode": "^1.70.0"},
        "categories": ["Themes"],
        "contributes": {"themes": themes},
    }, indent=2)
    payload["extension.vsixmanifest"] = MANIFEST.format(name=NAME, ver=ver, pub=PUB)
    payload["[Content_Types].xml"] = CONTENT_TYPES

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for k, v in payload.items():
            z.writestr(k, v)
    return ver, themes


def install(vsix):
    for cli, ext_dir in EDITORS:
        if not shutil.which(cli):
            print(f"  {cli:12} not installed, skipped")
            continue
        # A same-version install is a no-op, so drop the old copy first.
        for d in os.listdir(ext_dir) if os.path.isdir(ext_dir) else []:
            if d.startswith(f"{PUB}.{NAME}-"):
                subprocess.run([cli, "--uninstall-extension", f"{PUB}.{NAME}"],
                               capture_output=True, env=_clean_env())
                break
        r = subprocess.run([cli, "--install-extension", vsix],
                           capture_output=True, text=True, env=_clean_env())
        ok = "successfully installed" in (r.stdout + r.stderr)
        print(f"  {cli:12} {'installed' if ok else 'FAILED: ' + r.stdout.strip()[-160:]}")


def _clean_env():
    """GUI-adjacent CLIs inherit this shell's env; strip the Claude markers."""
    e = dict(os.environ)
    for k in ("CLAUDE_CODE_CHILD_SESSION", "CLAUDECODE"):
        e.pop(k, None)
    return e


if __name__ == "__main__":
    names = theme_names()
    out = os.path.join(tempfile.gettempdir(), f"{PUB}.{NAME}.vsix")
    ver, themes = make_vsix(names, out)
    print(f"built {out}  v{ver}  {len(themes)} themes")
    if "--build" in sys.argv:
        sys.exit(0)
    install(out)

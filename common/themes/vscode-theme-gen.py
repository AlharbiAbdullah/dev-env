#!/usr/bin/env python3
"""
vscode-theme-gen.py — build a VS Code / Cursor color theme from a theme.lua.

Companion to the OpenCode generator inside ~/.local/bin/theme, and it follows the
same contract: the SIGNATURE colors (background, foreground, the 16 ANSI slots,
selection) are written EXACT, and the neutral chrome the 16-color palette does not
define is derived by blending background -> foreground. Dark themes step lighter,
light themes step darker. The loud accent is reserved for focus/active borders and
never becomes a fill.

Why this exists: Cursor was the one adapter that could not be driven from theme.lua,
so every theme depended on some extension author happening to publish a matching
palette. They mostly do not. base16-terracotta-dark, the closest published match for
terramour, differs on every single color and sits 9 L* darker than the real ground.

Usage:
  python3 vscode-theme-gen.py <theme> [<outfile>]
"""
import json
import os
import re
import sys

THEMES = os.path.expanduser("~/.config/themes")


# ---------------------------------------------------------------- palette read

def read_theme(name):
    src = open(os.path.join(THEMES, name, "theme.lua"), encoding="utf-8").read()

    def field(key, default=""):
        m = re.search(rf'{key}\s*=\s*"([^"]+)"', src)
        return m.group(1) if m else default

    def clist(key):
        m = re.search(rf"{key}\s*=\s*\{{(.*?)\}}", src, re.S)
        return re.findall(r'"(#[0-9a-fA-F]{6})"', m.group(1)) if m else []

    border = field("border")
    return {
        "name": name,
        "mode": field("macos", "dark"),
        "bg": field("background"),
        "fg": field("foreground"),
        "cursor": field("cursor_bg") or field("foreground"),
        "sel_bg": field("selection_bg"),
        "accent": "#" + border[-6:] if border.startswith("0x") else (border or None),
        "ansi": clist("ansi"),
        "brights": clist("brights"),
    }


# ------------------------------------------------------------------ color math

def _rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mix(c1, c2, t):
    a, b = _rgb(c1), _rgb(c2)
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(a[i] + (b[i] - a[i]) * t))) for i in range(3))


def alpha(c, a):
    """Hex with an alpha suffix. VS Code wants #RRGGBBAA."""
    return c + "%02x" % max(0, min(255, round(a * 255)))


def build(t):
    bg, fg = t["bg"], t["fg"]
    ansi, br = t["ansi"], t["brights"] or t["ansi"]
    # ansi slots: 0 black 1 red 2 green 3 yellow 4 blue 5 magenta 6 cyan 7 white
    red, green, yellow, blue, magenta, cyan = (ansi[i] for i in range(1, 7))
    accent = t["accent"] or blue
    sel = t["sel_bg"] or mix(bg, fg, 0.12)

    # Neutral chrome elevations. Same ladder as the OpenCode generator.
    panel = mix(bg, fg, 0.06)     # sidebars, panels: a hair off the floor
    elem = mix(bg, fg, 0.12)      # inputs, hovered rows
    raise_ = mix(bg, fg, 0.18)    # widgets that float above the editor
    line = mix(bg, fg, 0.14)      # subtle separators
    border = mix(bg, fg, 0.24)    # visible but quiet borders
    muted = mix(bg, fg, 0.55)     # comments, dimmed text
    faint = mix(bg, fg, 0.38)     # whitespace, indent guides
    ghost = mix(bg, fg, 0.03)     # current-line highlight

    C = {
        # base
        "foreground": fg,
        "focusBorder": accent,
        "descriptionForeground": muted,
        "errorForeground": red,
        "disabledForeground": faint,
        "icon.foreground": muted,
        "selection.background": sel,
        "widget.shadow": alpha(_darkest(bg), 0.35),
        "widget.border": border,
        "sash.hoverBorder": accent,
        "textLink.foreground": accent,
        "textLink.activeForeground": fg,
        "textPreformat.foreground": yellow,
        "textBlockQuote.background": panel,
        "textBlockQuote.border": border,
        "textCodeBlock.background": panel,
        "textSeparator.foreground": border,

        # buttons, inputs, dropdowns
        "button.background": accent,
        "button.foreground": bg,
        "button.hoverBackground": mix(accent, fg, 0.12),
        "button.secondaryBackground": elem,
        "button.secondaryForeground": fg,
        "button.secondaryHoverBackground": raise_,
        "checkbox.background": elem,
        "checkbox.border": border,
        "dropdown.background": elem,
        "dropdown.foreground": fg,
        "dropdown.border": border,
        "dropdown.listBackground": raise_,
        "input.background": elem,
        "input.foreground": fg,
        "input.border": border,
        "input.placeholderForeground": faint,
        "inputOption.activeBorder": accent,
        "inputOption.activeForeground": fg,
        "inputValidation.errorBackground": mix(bg, red, 0.18),
        "inputValidation.errorBorder": red,
        "inputValidation.warningBackground": mix(bg, yellow, 0.18),
        "inputValidation.warningBorder": yellow,
        "inputValidation.infoBackground": mix(bg, blue, 0.18),
        "inputValidation.infoBorder": blue,

        # scrollbar, badge, progress
        "scrollbar.shadow": alpha(_darkest(bg), 0.30),
        "scrollbarSlider.background": alpha(fg, 0.10),
        "scrollbarSlider.hoverBackground": alpha(fg, 0.16),
        "scrollbarSlider.activeBackground": alpha(fg, 0.22),
        "badge.background": accent,
        "badge.foreground": bg,
        "progressBar.background": accent,

        # lists and trees
        "list.activeSelectionBackground": elem,
        "list.activeSelectionForeground": fg,
        "list.inactiveSelectionBackground": mix(bg, fg, 0.09),
        "list.inactiveSelectionForeground": fg,
        "list.hoverBackground": mix(bg, fg, 0.07),
        "list.hoverForeground": fg,
        "list.focusBackground": elem,
        "list.focusForeground": fg,
        "list.highlightForeground": accent,
        "list.errorForeground": red,
        "list.warningForeground": yellow,
        "tree.indentGuidesStroke": faint,

        # activity bar
        "activityBar.background": bg,
        "activityBar.foreground": fg,
        "activityBar.inactiveForeground": faint,
        "activityBar.border": line,
        "activityBarBadge.background": accent,
        "activityBarBadge.foreground": bg,

        # side bar
        "sideBar.background": panel,
        "sideBar.foreground": mix(bg, fg, 0.80),
        "sideBar.border": line,
        "sideBarTitle.foreground": fg,
        "sideBarSectionHeader.background": panel,
        "sideBarSectionHeader.foreground": fg,
        "sideBarSectionHeader.border": line,

        # editor groups and tabs
        "editorGroup.border": line,
        "editorGroupHeader.tabsBackground": panel,
        "editorGroupHeader.tabsBorder": line,
        "editorGroupHeader.noTabsBackground": panel,
        "tab.activeBackground": bg,
        "tab.activeForeground": fg,
        "tab.activeBorderTop": accent,
        "tab.inactiveBackground": panel,
        "tab.inactiveForeground": muted,
        "tab.border": line,
        "tab.hoverBackground": elem,
        "tab.unfocusedActiveForeground": muted,
        "tab.lastPinnedBorder": border,

        # editor core
        "editor.background": bg,
        "editor.foreground": fg,
        "editorLineNumber.foreground": faint,
        "editorLineNumber.activeForeground": mix(bg, fg, 0.72),
        "editorCursor.foreground": t["cursor"],
        "editor.selectionBackground": sel,
        "editor.selectionHighlightBackground": alpha(fg, 0.08),
        "editor.inactiveSelectionBackground": mix(bg, fg, 0.09),
        "editor.wordHighlightBackground": alpha(blue, 0.14),
        "editor.wordHighlightStrongBackground": alpha(green, 0.14),
        "editor.findMatchBackground": alpha(yellow, 0.32),
        "editor.findMatchHighlightBackground": alpha(yellow, 0.16),
        "editor.hoverHighlightBackground": alpha(blue, 0.12),
        "editor.lineHighlightBackground": ghost,
        "editor.rangeHighlightBackground": alpha(fg, 0.06),
        "editorWhitespace.foreground": mix(bg, fg, 0.22),
        "editorIndentGuide.background1": mix(bg, fg, 0.13),
        "editorIndentGuide.activeBackground1": mix(bg, fg, 0.30),
        "editorRuler.foreground": line,
        "editorCodeLens.foreground": muted,
        "editorBracketMatch.background": alpha(accent, 0.18),
        "editorBracketMatch.border": alpha(accent, 0.60),
        "editorLink.activeForeground": accent,

        # bracket pair colors, walked around the palette
        "editorBracketHighlight.foreground1": yellow,
        "editorBracketHighlight.foreground2": magenta,
        "editorBracketHighlight.foreground3": cyan,
        "editorBracketHighlight.foreground4": green,
        "editorBracketHighlight.foreground5": blue,
        "editorBracketHighlight.foreground6": red,
        "editorBracketHighlight.unexpectedBracket.foreground": red,

        # gutter and diagnostics
        "editorGutter.background": bg,
        "editorGutter.modifiedBackground": blue,
        "editorGutter.addedBackground": green,
        "editorGutter.deletedBackground": red,
        "editorError.foreground": red,
        "editorWarning.foreground": yellow,
        "editorInfo.foreground": blue,
        "editorHint.foreground": cyan,
        "problemsErrorIcon.foreground": red,
        "problemsWarningIcon.foreground": yellow,
        "problemsInfoIcon.foreground": blue,

        # overview ruler
        "editorOverviewRuler.border": line,
        "editorOverviewRuler.errorForeground": red,
        "editorOverviewRuler.warningForeground": yellow,
        "editorOverviewRuler.infoForeground": blue,
        "editorOverviewRuler.findMatchForeground": alpha(yellow, 0.60),
        "editorOverviewRuler.addedForeground": green,
        "editorOverviewRuler.modifiedForeground": blue,
        "editorOverviewRuler.deletedForeground": red,

        # diff
        "diffEditor.insertedTextBackground": alpha(green, 0.13),
        "diffEditor.removedTextBackground": alpha(red, 0.13),
        "diffEditor.insertedLineBackground": alpha(green, 0.09),
        "diffEditor.removedLineBackground": alpha(red, 0.09),
        "diffEditor.diagonalFill": line,

        # floating widgets
        "editorWidget.background": raise_,
        "editorWidget.foreground": fg,
        "editorWidget.border": border,
        "editorHoverWidget.background": raise_,
        "editorHoverWidget.border": border,
        "editorSuggestWidget.background": raise_,
        "editorSuggestWidget.foreground": fg,
        "editorSuggestWidget.border": border,
        "editorSuggestWidget.selectedBackground": elem,
        "editorSuggestWidget.highlightForeground": accent,
        "peekView.border": accent,
        "peekViewEditor.background": panel,
        "peekViewEditor.matchHighlightBackground": alpha(yellow, 0.25),
        "peekViewResult.background": panel,
        "peekViewResult.selectionBackground": elem,
        "peekViewTitle.background": raise_,
        "peekViewTitleLabel.foreground": fg,
        "peekViewTitleDescription.foreground": muted,

        # merge conflicts
        "merge.currentHeaderBackground": alpha(green, 0.28),
        "merge.currentContentBackground": alpha(green, 0.13),
        "merge.incomingHeaderBackground": alpha(blue, 0.28),
        "merge.incomingContentBackground": alpha(blue, 0.13),

        # panel and terminal chrome
        "panel.background": panel,
        "panel.border": line,
        "panelTitle.activeForeground": fg,
        "panelTitle.activeBorder": accent,
        "panelTitle.inactiveForeground": muted,

        # status bar
        "statusBar.background": panel,
        "statusBar.foreground": mix(bg, fg, 0.75),
        "statusBar.border": line,
        "statusBar.debuggingBackground": yellow,
        "statusBar.debuggingForeground": bg,
        "statusBar.noFolderBackground": panel,
        "statusBarItem.remoteBackground": accent,
        "statusBarItem.remoteForeground": bg,
        "statusBarItem.hoverBackground": alpha(fg, 0.08),
        "statusBarItem.errorBackground": red,
        "statusBarItem.errorForeground": bg,
        "statusBarItem.warningBackground": yellow,
        "statusBarItem.warningForeground": bg,

        # title bar
        "titleBar.activeBackground": panel,
        "titleBar.activeForeground": fg,
        "titleBar.inactiveBackground": panel,
        "titleBar.inactiveForeground": muted,
        "titleBar.border": line,

        # menus
        "menubar.selectionBackground": elem,
        "menubar.selectionForeground": fg,
        "menu.background": raise_,
        "menu.foreground": fg,
        "menu.border": border,
        "menu.selectionBackground": elem,
        "menu.selectionForeground": fg,
        "menu.separatorBackground": border,

        # notifications
        "notificationCenterHeader.background": raise_,
        "notifications.background": raise_,
        "notifications.foreground": fg,
        "notifications.border": border,
        "notificationLink.foreground": accent,
        "notificationsErrorIcon.foreground": red,
        "notificationsWarningIcon.foreground": yellow,
        "notificationsInfoIcon.foreground": blue,

        # quick input / command palette
        "quickInput.background": raise_,
        "quickInput.foreground": fg,
        "quickInputList.focusBackground": elem,
        "quickInputList.focusForeground": fg,
        "pickerGroup.foreground": muted,
        "pickerGroup.border": border,

        # breadcrumbs
        "breadcrumb.background": bg,
        "breadcrumb.foreground": muted,
        "breadcrumb.focusForeground": fg,
        "breadcrumb.activeSelectionForeground": accent,
        "breadcrumbPicker.background": raise_,

        # git decorations
        "gitDecoration.addedResourceForeground": green,
        "gitDecoration.modifiedResourceForeground": blue,
        "gitDecoration.deletedResourceForeground": red,
        "gitDecoration.untrackedResourceForeground": green,
        "gitDecoration.ignoredResourceForeground": faint,
        "gitDecoration.conflictingResourceForeground": magenta,
        "gitDecoration.stageModifiedResourceForeground": yellow,

        # settings editor
        "settings.headerForeground": fg,
        "settings.modifiedItemIndicator": accent,
        "settings.dropdownBackground": elem,
        "settings.dropdownBorder": border,
        "settings.textInputBackground": elem,
        "settings.textInputBorder": border,
        "settings.numberInputBackground": elem,
        "settings.numberInputBorder": border,

        # minimap
        "minimap.findMatchHighlight": alpha(yellow, 0.50),
        "minimap.selectionHighlight": sel,
        "minimap.errorHighlight": red,
        "minimap.warningHighlight": yellow,
        "minimapSlider.background": alpha(fg, 0.08),
        "minimapSlider.hoverBackground": alpha(fg, 0.12),
        "minimapSlider.activeBackground": alpha(fg, 0.16),

        # inline AI suggestions. Cursor leans on these constantly, and an unstyled
        # ghost text renders at VS Code's default grey, which reads as a different
        # theme bleeding through mid-edit.
        "editorGhostText.foreground": mix(bg, fg, 0.42),
        "editorGhostText.border": "#00000000",
        "editorInlayHint.foreground": muted,
        "editorInlayHint.background": alpha(fg, 0.06),
        "editorInlayHint.typeForeground": mix(blue, fg, 0.25),
        "editorInlayHint.typeBackground": alpha(fg, 0.06),
        "editorInlayHint.parameterForeground": mix(cyan, fg, 0.25),
        "editorInlayHint.parameterBackground": alpha(fg, 0.06),
        "editorStickyScroll.background": panel,
        "editorStickyScrollHover.background": elem,
        "editorLightBulb.foreground": yellow,
        "editorLightBulbAutoFix.foreground": green,
        "editorUnnecessaryCode.opacity": alpha("#000000", 0.55),

        # notebooks
        "notebook.editorBackground": bg,
        "notebook.cellBorderColor": line,
        "notebook.cellEditorBackground": panel,
        "notebook.cellHoverBackground": ghost,
        "notebook.focusedCellBackground": ghost,
        "notebook.focusedCellBorder": accent,
        "notebook.inactiveFocusedCellBorder": border,
        "notebook.outputContainerBackgroundColor": panel,
        "notebook.selectedCellBackground": elem,
        "notebook.selectedCellBorder": border,
        "notebookStatusSuccessIcon.foreground": green,
        "notebookStatusErrorIcon.foreground": red,
        "notebookStatusRunningIcon.foreground": blue,

        # debug console and debug UI
        "debugConsole.infoForeground": blue,
        "debugConsole.warningForeground": yellow,
        "debugConsole.errorForeground": red,
        "debugConsole.sourceForeground": muted,
        "debugConsoleInputIcon.foreground": accent,
        "debugToolBar.background": raise_,
        "debugToolBar.border": border,
        "debugView.stateLabelBackground": elem,
        "debugView.stateLabelForeground": fg,
        "debugView.valueChangedHighlight": alpha(blue, 0.45),
        "debugTokenExpression.name": cyan,
        "debugTokenExpression.value": fg,
        "debugTokenExpression.string": yellow,
        "debugTokenExpression.number": magenta,
        "debugTokenExpression.boolean": magenta,
        "debugTokenExpression.error": red,
        "debugIcon.breakpointForeground": red,
        "debugIcon.breakpointDisabledForeground": faint,
        "debugIcon.continueForeground": green,
        "debugIcon.pauseForeground": yellow,
        "debugIcon.stopForeground": red,
        "debugIcon.stepOverForeground": blue,
        "debugIcon.stepIntoForeground": blue,
        "debugIcon.stepOutForeground": blue,
        "debugIcon.restartForeground": green,
        "debugIcon.startForeground": green,

        # testing
        "testing.iconPassed": green,
        "testing.iconFailed": red,
        "testing.iconErrored": red,
        "testing.iconSkipped": faint,
        "testing.iconQueued": yellow,
        "testing.iconUnset": faint,
        "testing.runAction": green,
        "testing.message.error.decorationForeground": red,
        "testing.message.info.decorationForeground": blue,

        # charts (used by profilers and some extensions)
        "charts.foreground": fg,
        "charts.lines": border,
        "charts.red": red,
        "charts.blue": blue,
        "charts.yellow": yellow,
        "charts.orange": mix(red, yellow, 0.5),
        "charts.green": green,
        "charts.purple": magenta,

        # command center, banners, keybinding labels
        "commandCenter.background": elem,
        "commandCenter.foreground": fg,
        "commandCenter.border": border,
        "commandCenter.activeBackground": raise_,
        "banner.background": elem,
        "banner.foreground": fg,
        "banner.iconForeground": accent,
        "keybindingLabel.background": elem,
        "keybindingLabel.foreground": fg,
        "keybindingLabel.border": border,
        "keybindingLabel.bottomBorder": border,
        "extensionButton.prominentBackground": accent,
        "extensionButton.prominentForeground": bg,
        "extensionBadge.remoteBackground": accent,
        "extensionIcon.starForeground": yellow,
        "walkThrough.embeddedEditorBackground": panel,
        "welcomePage.background": bg,
        "welcomePage.tileBackground": panel,
        "welcomePage.tileHoverBackground": elem,
        "welcomePage.progress.background": elem,
        "welcomePage.progress.foreground": accent,

        # integrated terminal: exact, so it matches iTerm2 to the hex
        "terminal.background": bg,
        # (symbolIcon.* is appended below, driven off the same role map as syntax)
        "terminal.foreground": fg,
        "terminalCursor.foreground": t["cursor"],
        "terminal.selectionBackground": sel,
        "terminal.border": line,
        "terminal.ansiBlack": ansi[0],
        "terminal.ansiRed": ansi[1],
        "terminal.ansiGreen": ansi[2],
        "terminal.ansiYellow": ansi[3],
        "terminal.ansiBlue": ansi[4],
        "terminal.ansiMagenta": ansi[5],
        "terminal.ansiCyan": ansi[6],
        "terminal.ansiWhite": ansi[7],
        "terminal.ansiBrightBlack": br[0],
        "terminal.ansiBrightRed": br[1],
        "terminal.ansiBrightGreen": br[2],
        "terminal.ansiBrightYellow": br[3],
        "terminal.ansiBrightBlue": br[4],
        "terminal.ansiBrightMagenta": br[5],
        "terminal.ansiBrightCyan": br[6],
        "terminal.ansiBrightWhite": br[7],
    }

    # Autocomplete symbol icons. Same role -> hue map as the syntax rules below,
    # so a function in the suggest list is the colour a function is in the buffer.
    symbol_roles = {
        green: ["function", "method", "constructor", "event", "operator"],
        blue: ["class", "interface", "struct", "namespace", "module", "package", "typeParameter"],
        magenta: ["constant", "enumerator", "enumeratorMember", "number", "boolean", "null", "unit"],
        cyan: ["field", "property", "variable", "key", "reference", "snippet"],
        yellow: ["string", "text", "array", "object", "keyword"],
        red: ["color", "value"],
        muted: ["file", "folder"],
    }
    for hue, names in symbol_roles.items():
        for n in names:
            C[f"symbolIcon.{n}Foreground"] = hue

    # Syntax mapping copied from sainnhe's gruvbox-material / everforest, the two
    # themes that scored highest on the comfort ranking. Roles, not hues, so it
    # transfers to any palette.
    def rule(name, scope, color=None, style=None):
        s = {}
        if color:
            s["foreground"] = color
        if style:
            s["fontStyle"] = style
        return {"name": name, "scope": scope, "settings": s}

    T = [
        rule("Comment", ["comment", "punctuation.definition.comment", "string.comment"], muted, "italic"),
        rule("String", ["string", "string.quoted", "meta.embedded.assembly"], yellow),
        rule("String escape", ["constant.character.escape", "string.regexp"], magenta),
        rule("Number", ["constant.numeric", "constant.language", "constant.character"], magenta),
        rule("Boolean / null", ["constant.language.boolean", "constant.language.null", "constant.language.undefined"], magenta),
        rule("Keyword", ["keyword", "keyword.control", "keyword.other"], red),
        rule("Operator", ["keyword.operator"], mix(fg, red, 0.30)),
        rule("Storage", ["storage", "storage.type", "storage.modifier"], red),
        rule("Function", ["entity.name.function", "meta.function-call", "support.function", "variable.function"], green),
        rule("Method declaration", ["entity.name.method", "meta.definition.method"], green),
        rule("Class / type", ["entity.name.type", "entity.name.class", "support.type", "support.class", "entity.other.inherited-class"], blue),
        rule("Namespace", ["entity.name.namespace", "entity.name.module"], blue),
        rule("Variable", ["variable", "variable.other", "meta.definition.variable"], fg),
        rule("Parameter", ["variable.parameter", "meta.parameter"], cyan),
        rule("Property", ["variable.other.property", "support.variable.property", "meta.object-literal.key"], cyan),
        rule("Constant", ["variable.other.constant", "support.constant"], magenta),
        rule("This / self", ["variable.language", "variable.language.this"], magenta),
        rule("Tag", ["entity.name.tag", "meta.tag"], red),
        rule("Attribute", ["entity.other.attribute-name"], green),
        rule("Punctuation", ["punctuation", "meta.brace", "punctuation.separator", "punctuation.terminator"], mix(fg, bg, 0.22)),
        rule("Decorator", ["meta.decorator", "entity.name.function.decorator", "punctuation.decorator"], yellow),
        rule("Invalid", ["invalid", "invalid.illegal"], red, "underline"),
        rule("Deprecated", ["invalid.deprecated"], muted, "strikethrough"),
        # markup
        rule("Heading", ["markup.heading", "entity.name.section"], accent, "bold"),
        rule("Bold", ["markup.bold"], red, "bold"),
        rule("Italic", ["markup.italic"], magenta, "italic"),
        rule("Link", ["markup.underline.link", "string.other.link"], accent, "underline"),
        rule("Quote", ["markup.quote"], muted, "italic"),
        rule("List", ["markup.list", "punctuation.definition.list"], cyan),
        rule("Inline code", ["markup.inline.raw", "markup.raw"], green),
        rule("Diff inserted", ["markup.inserted"], green),
        rule("Diff deleted", ["markup.deleted"], red),
        rule("Diff changed", ["markup.changed"], blue),
        # config / data formats
        rule("JSON key", ["support.type.property-name.json"], cyan),
        rule("YAML key", ["entity.name.tag.yaml"], cyan),
        rule("TOML key", ["support.type.property-name.toml"], cyan),
        rule("Shell variable", ["variable.other.normal.shell", "string.interpolated"], cyan),
    ]

    return {
        "$schema": "vscode://schemas/color-theme",
        "name": f"{t['name'].title().replace('-', ' ')} (generated)",
        "type": "dark" if t["mode"] == "dark" else "light",
        "semanticHighlighting": True,
        "colors": C,
        "tokenColors": T,
        "semanticTokenColors": {
            "parameter": cyan,
            "property": cyan,
            "variable.constant": magenta,
            "function": green,
            "method": green,
            "class": blue,
            "type": blue,
            "namespace": blue,
            "enumMember": magenta,
            "decorator": yellow,
        },
    }


def _darkest(bg):
    """A near-black derived from the theme's own ground, for shadows."""
    return mix(bg, "#000000", 0.65)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("usage: vscode-theme-gen.py <theme> [<outfile>]")
    name = sys.argv[1]
    theme = build(read_theme(name))
    out = sys.argv[2] if len(sys.argv) > 2 else f"{name}-generated.json"
    with open(out, "w") as f:
        json.dump(theme, f, indent=2)
    print(f"{out}: {len(theme['colors'])} color keys, {len(theme['tokenColors'])} token rules")

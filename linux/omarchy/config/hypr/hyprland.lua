-- Omarchy 4 entry point (user-owned). Mirrors the shipped default except the
-- preinstalled-app bindings are off: this box never used the webapp binds.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

omarchy_preinstalled_bindings = false

require("default.hypr.omarchy")

-- OCR keybind (Super+Ctrl+Print) reads Arabic too; needs tesseract-data-ara.
hl.env("OMARCHY_OCR_LANGS", "eng+ara")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

require("default.hypr.toggles")

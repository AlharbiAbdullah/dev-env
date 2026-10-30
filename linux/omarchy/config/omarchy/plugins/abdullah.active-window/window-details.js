// Window titles are the source of folder names; never guess a browser's folder.
function folderName(path) {
  var value = String(path || "").trim()
  if (!value) return ""
  var clean = value.replace(/\/+$/, "")
  return clean === "~" ? "home" : (clean.split("/").pop() || "/")
}

function programName(appId) {
  var id = String(appId || "")
  if (/ghostty/i.test(id)) return "Ghostty"
  if (/chrome/i.test(id)) return "Chrome"
  if (/obsidian/i.test(id)) return "Obsidian"
  if (/vscode|visualstudiocode|^code$/i.test(id)) return "VS Code"
  if (/cursor/i.test(id)) return "Cursor"
  if (/firefox/i.test(id)) return "Firefox"
  return id.split(".").pop() || "Window"
}

function format(appId, title) {
  var program = programName(appId)
  var details = String(title || "").trim()
  var folder = ""
  var parts
  if (program === "Ghostty") {
    parts = details.split(/\s+\|\s+/)
    if (parts.length > 1) {
      folder = folderName(parts.pop())
      details = parts.join(" | ")
    } else {
      var path = details.match(/^(?:[^\s]+@[^\s:]+:)?([~\/].*)$/)
      if (path) {
        folder = folderName(path[1])
        details = ""
      }
    }
  } else if (program === "VS Code" || program === "Cursor" || program === "Obsidian") {
    details = details.replace(/\s+[-–—]\s+(?:Visual Studio Code|Cursor|Obsidian)(?:\s+\d[\w.]*)?$/, "")
    parts = details.split(/\s+[-–—]\s+/)
    folder = folderName(parts.pop())
    details = parts.join(" - ")
    if (/^(?:Welcome|Settings|Extensions|Untitled(?:-\d+)?|Obsidian)$/i.test(folder)) {
      details = details ? details + " - " + folder : folder
      folder = ""
    }
  } else if (program === "Chrome" || program === "Firefox") {
    details = details.replace(/\s+[-–—]\s+(?:Google Chrome|Mozilla Firefox)$/, "")
  }
  if (details.toLowerCase() === program.toLowerCase()) details = ""
  var fields = [program]
  if (folder) fields.push(folder)
  if (details) fields.push(details)
  return { program: program, folder: folder, details: details, text: fields.join(" - ") }
}

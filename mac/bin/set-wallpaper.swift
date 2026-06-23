// set-wallpaper <image-path>
// macOS Sonoma+/Tahoe: the legacy System Events "set picture" sets a path but no
// longer repaints the live desktop. NSWorkspace.setDesktopImageURL is the API that
// actually applies + renders the wallpaper, on every attached screen.
import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: set-wallpaper <image-path>\n".data(using: .utf8)!)
    exit(2)
}
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard FileManager.default.fileExists(atPath: url.path) else {
    FileHandle.standardError.write("set-wallpaper: not found: \(url.path)\n".data(using: .utf8)!)
    exit(1)
}
for screen in NSScreen.screens {
    do { try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:]) }
    catch { FileHandle.standardError.write("set-wallpaper: \(error)\n".data(using: .utf8)!) }
}

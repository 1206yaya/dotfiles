import ScreenCaptureKit
import Cocoa

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: capture-screen <output-path>\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]

Task {
    do {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true
        )

        let mouse = NSEvent.mouseLocation
        let screens = NSScreen.screens

        // マウスカーソルがあるスクリーンを特定
        var targetDisplay: SCDisplay?
        for screen in screens {
            if screen.frame.contains(mouse) {
                let screenNumber = screen.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as! CGDirectDisplayID
                targetDisplay = content.displays.first { $0.displayID == screenNumber }
                break
            }
        }

        guard let display = targetDisplay else {
            fputs("ERROR: display not found\n", stderr)
            exit(1)
        }

        // Raycast 自身のウィンドウを除外して撮影（view モードで Raycast UI が前面にいてもOK）
        let raycastApps = content.applications.filter {
            $0.bundleIdentifier.hasPrefix("com.raycast")
        }
        let filter = SCContentFilter(
            display: display,
            excludingApplications: raycastApps,
            exceptingWindows: []
        )
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            fputs("ERROR: PNG conversion failed\n", stderr)
            exit(1)
        }

        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print(outputPath)
        exit(0)

    } catch {
        fputs("ERROR: \(error)\n", stderr)
        exit(1)
    }
}

dispatchMain()

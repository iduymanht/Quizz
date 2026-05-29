import AppKit
import SwiftUI

/// Owns the onboarding/Settings window, shown on first launch and reopenable
/// from the menu bar.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show() {
        SettingsModel.shared.refresh()

        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: SetupView(onClose: { [weak self] in
            self?.window?.close()
        }))
        let window = NSWindow(contentViewController: hosting)
        window.title = "AgentPet"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Shows onboarding only the first time the app is ever launched.
    func showOnFirstLaunch() {
        let key = "agentpet.hasOnboarded"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        show()
    }
}

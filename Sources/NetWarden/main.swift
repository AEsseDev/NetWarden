import AppKit
import SwiftUI

@MainActor
final class NetWardenAppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let model = AppModel()
    private var dashboardController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.info("app", "applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
        model.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.info("app", "applicationWillTerminate")
        model.stop()
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.title = ""
        button.image = NSImage(systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: "NetWarden")
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        AppLogger.shared.info("ui", "Status item инициализирован")
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 380)

        let root = PopoverView(
            model: model,
            onOpenDashboard: { [weak self] in self?.openDashboard() },
            onQuit: { NSApp.terminate(nil) }
        )
        popover.contentViewController = NSHostingController(rootView: root)
        AppLogger.shared.info("ui", "Popover инициализирован")
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            AppLogger.shared.debug("ui", "Клик по status bar: right -> open dashboard")
            openDashboard()
            return
        }

        if popover.isShown {
            AppLogger.shared.debug("ui", "Popover закрыт")
            popover.performClose(sender)
        } else {
            AppLogger.shared.debug("ui", "Popover открыт")
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func openDashboard() {
        if let window = dashboardController?.window {
            AppLogger.shared.debug("ui", "Dashboard уже открыт, вывод на передний план")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboard = DashboardView(model: model)
        let controller = NSWindowController(window: NSWindow(contentViewController: NSHostingController(rootView: dashboard)))
        controller.window?.title = "NetWarden"
        controller.window?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        controller.window?.setContentSize(NSSize(width: 1080, height: 700))
        controller.window?.center()
        controller.window?.isReleasedWhenClosed = false
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        dashboardController = controller
        AppLogger.shared.info("ui", "Dashboard создан и открыт")
    }
}

AppLogger.shared.info("app", "Запуск процесса NetWarden pid=\(ProcessInfo.processInfo.processIdentifier)")
let app = NSApplication.shared
let delegate = NetWardenAppDelegate()
app.delegate = delegate
app.run()

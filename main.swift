import AppKit
import CoreGraphics
import ServiceManagement

// MARK: - Scroll inverter

/// Taps the scroll-wheel event stream and flips the direction of events that
/// came from a wheel mouse, leaving trackpad gestures untouched.
final class ScrollInverter {
    var invertHorizontal = false

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let debug = ProcessInfo.processInfo.environment["IMO_DEBUG"] == "1"

    var isRunning: Bool { tap != nil }

    /// Installs the event tap. Returns false if macOS refused, which in
    /// practice always means Accessibility permission has not been granted.
    @discardableResult
    func start() -> Bool {
        if tap != nil { return true }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                let inverter = Unmanaged<ScrollInverter>.fromOpaque(refcon!).takeUnretainedValue()
                return inverter.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.source = source
        return true
    }

    func stop() {
        guard let tap, let source else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        CFMachPortInvalidate(tap)
        self.tap = nil
        self.source = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let passthrough = Unmanaged.passUnretained(event)

        // macOS disarms a tap that is slow to respond or that fires during
        // certain input; re-arm it rather than silently dying.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return passthrough
        }
        guard type == .scrollWheel else { return passthrough }

        // Trackpads and the Magic Mouse send continuous pixel deltas; a wheel
        // mouse sends discrete line deltas. Only the latter gets flipped.
        let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0

        if debug {
            FileHandle.standardError.write("""
                scroll continuous=\(continuous) \
                axis1=\(event.getIntegerValueField(.scrollWheelEventDeltaAxis1)) \
                axis2=\(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))

                """.data(using: .utf8)!)
        }

        guard !continuous else { return passthrough }

        invert(event, .vertical)
        if invertHorizontal { invert(event, .horizontal) }
        return passthrough
    }

    private enum Axis { case vertical, horizontal }

    private func invert(_ event: CGEvent, _ axis: Axis) {
        let vertical = axis == .vertical
        let fixedPt: CGEventField = vertical ? .scrollWheelEventFixedPtDeltaAxis1 : .scrollWheelEventFixedPtDeltaAxis2
        let point: CGEventField = vertical ? .scrollWheelEventPointDeltaAxis1 : .scrollWheelEventPointDeltaAxis2
        let delta: CGEventField = vertical ? .scrollWheelEventDeltaAxis1 : .scrollWheelEventDeltaAxis2

        // The three representations of a delta are linked: writing one rewrites
        // the others. Read all of them before writing any.
        let f = event.getDoubleValueField(fixedPt)
        let p = event.getIntegerValueField(point)
        let d = event.getIntegerValueField(delta)

        event.setDoubleValueField(fixedPt, value: -f)
        event.setIntegerValueField(point, value: -p)
        event.setIntegerValueField(delta, value: -d)
    }
}

// MARK: - Menu bar app

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let inverter = ScrollInverter()
    private let defaults = UserDefaults.standard
    private var statusItem: NSStatusItem?
    private var permissionPoll: Timer?

    private var isEnabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    private var hidesIcon: Bool {
        get { defaults.bool(forKey: "hideMenuBarIcon") }
        set { defaults.set(newValue, forKey: "hideMenuBarIcon") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        inverter.invertHorizontal = defaults.bool(forKey: "invertHorizontal")
        refresh()

        if isEnabled { requestPermissionAndStart() }
    }

    /// Launching an already-running app (Finder, Spotlight, `open -a`) sends a
    /// reopen instead of a second instance. That is the way back to a hidden
    /// icon, so treat it as "show yourself".
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if hidesIcon {
            hidesIcon = false
            refresh()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        inverter.stop()
    }

    // MARK: Permission

    private func requestPermissionAndStart() {
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(prompt), inverter.start() {
            refresh()
            return
        }
        // The grant happens in System Settings, out of band, so poll for it.
        permissionPoll?.invalidate()
        permissionPoll = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, AXIsProcessTrusted() else { return }
            timer.invalidate()
            self.permissionPoll = nil
            if self.isEnabled { self.inverter.start() }
            self.refresh()
        }
        refresh()
    }

    // MARK: Menu

    private func refresh() {
        guard !hidesIcon else {
            if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            statusItem = nil
            return
        }

        let statusItem = self.statusItem
            ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        let active = isEnabled && inverter.isRunning
        let symbol = active ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Invert Mouse Only")

        let menu = NSMenu()

        if !AXIsProcessTrusted() {
            menu.addItem(item("⚠︎  Grant Accessibility Permission…", #selector(openAccessibilitySettings)))
            menu.addItem(.separator())
        }

        menu.addItem(item("Invert Mouse Scrolling", #selector(toggleEnabled), on: isEnabled))
        menu.addItem(item("Also Invert Horizontal", #selector(toggleHorizontal), on: inverter.invertHorizontal))
        menu.addItem(.separator())
        menu.addItem(item("Launch at Login", #selector(toggleLaunchAtLogin), on: SMAppService.mainApp.status == .enabled))
        menu.addItem(item("Hide Menu Bar Icon", #selector(hideIcon)))
        menu.addItem(.separator())
        menu.addItem(item("Quit", #selector(quit), key: "q"))

        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, on: Bool = false, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    // MARK: Actions

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            requestPermissionAndStart()
        } else {
            inverter.stop()
            refresh()
        }
    }

    @objc private func toggleHorizontal() {
        inverter.invertHorizontal.toggle()
        defaults.set(inverter.invertHorizontal, forKey: "invertHorizontal")
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert(
                "Couldn't change the login item",
                "\(error.localizedDescription)\n\nAdd invertMouseOnly.app manually under System Settings › General › Login Items."
            )
        }
        refresh()
    }

    @objc private func hideIcon() {
        hidesIcon = true
        refresh()

        alert(
            "Menu bar icon hidden",
            """
            Invert Mouse Only keeps running and keeps inverting your mouse scroll.

            To bring the icon back, open the app again — double-click \
            invertMouseOnly.app, or run:
                open -a invertMouseOnly

            To quit it while hidden:
                killall invertMouseOnly
            """,
            style: .informational
        )
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func alert(_ message: String, _ info: String, style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = style
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

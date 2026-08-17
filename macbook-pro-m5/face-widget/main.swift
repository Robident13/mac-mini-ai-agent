import AppKit
import WebKit

// ── Model state ─────────────────────────────────────────────
enum FaceState: String {
    case idle, listening, thinking, loading, error
}

extension URLRequest {
    static func jsonPost(_ url: String) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        return request
    }
}

/// Transparent, borderless, always-on-top window that can still become key
/// (borderless windows refuse key status by default, which breaks the menu).
final class WidgetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

/// Sits on top of the web view and owns all mouse handling: drag to move,
/// right-click for the menu. The web content is purely decorative.
final class DragOverlay: NSView {
    var onQuit: (() -> Void)?
    var onClick: (() -> Void)?
    private var initialLocation: NSPoint?
    private var didDrag = false

    /// Signal that the widget is actionable, not just decoration.
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = initialLocation,
              let window = self.window,
              let screenFrame = window.screen?.visibleFrame else { return }

        let current = NSEvent.mouseLocation
        var origin = NSPoint(x: current.x - start.x, y: current.y - start.y)

        // Anything past a few pixels is a move, not a click.
        if abs(origin.x - window.frame.origin.x) > 3 || abs(origin.y - window.frame.origin.y) > 3 {
            didDrag = true
        }

        // Keep the widget on screen.
        let size = window.frame.size
        origin.x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - size.width)
        origin.y = min(max(origin.y, screenFrame.minY), screenFrame.maxY - size.height)

        window.setFrameOrigin(origin)
    }

    override func mouseUp(with event: NSEvent) {
        initialLocation = nil
        if didDrag {
            if let window = self.window {
                UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: "widgetOrigin")
            }
        } else {
            onClick?()
        }
        didDrag = false
    }

    var onSleep: (() -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Local LLM Face", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(NSMenuItem.separator())
        let sleep = NSMenuItem(title: "Put to Sleep Now", action: #selector(sleepTapped), keyEquivalent: "")
        sleep.target = self
        menu.addItem(sleep)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit Widget", action: #selector(quitTapped), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func quitTapped() { onQuit?() }
    @objc private func sleepTapped() { onSleep?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: WidgetWindow!
    private var webView: WKWebView!
    private var timer: Timer?
    private var ready = false
    private var pending: FaceState?
    private var current: FaceState = .idle

    func applicationDidFinishLaunching(_ notification: Notification) {
        let size = NSSize(width: 124, height: 70)

        window = WidgetWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

        // Restore last position, else bottom-right of the main screen.
        if let saved = UserDefaults.standard.string(forKey: "widgetOrigin") {
            window.setFrameOrigin(NSPointFromString(saved))
        } else if let visible = NSScreen.main?.visibleFrame {
            window.setFrameOrigin(NSPoint(x: visible.maxX - size.width - 24,
                                          y: visible.minY + 24))
        }

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = self

        let overlay = DragOverlay(frame: NSRect(origin: .zero, size: size))
        overlay.onQuit = { NSApp.terminate(nil) }
        overlay.onClick = { [weak self] in self?.wake() }
        overlay.onSleep = { [weak self] in self?.sleep() }

        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.addSubview(webView)
        container.addSubview(overlay)
        window.contentView = container
        window.makeKeyAndOrderFront(nil)

        if let html = Bundle.main.url(forResource: "face", withExtension: "html") {
            webView.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    private static let ollamaBundleID = "com.electron.ollama"
    private static let hermesBundleID = "com.nousresearch.hermes"
    private var waking = false

    // ── click: wake Ollama (if asleep), then open Hermes ────
    private func wake() {
        guard !waking else { return }

        // Already up: just bring Hermes forward and make sure the model is warm.
        if isRunning(bundleID: Self.ollamaBundleID) {
            preloadModel()
            openHermesApp()
            return
        }

        waking = true
        apply(.loading)

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false  // background service — no window to show
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/Applications/Ollama.app"),
            configuration: config
        ) { [weak self] _, _ in
            self?.pollUntilReady(attemptsLeft: 15)
        }
    }

    /// Ollama takes a few seconds to bind its API after the process starts.
    private func pollUntilReady(attemptsLeft: Int) {
        guard attemptsLeft > 0 else {
            waking = false
            apply(.error)  // a real failure: we asked it to wake and it didn't
            return
        }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:11434/api/version")!)
        request.timeoutInterval = 1.0
        URLSession.shared.dataTask(with: request) { [weak self] _, response, err in
            guard let self else { return }
            let ok = err == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                if ok {
                    self.waking = false
                    self.preloadModel()
                    self.openHermesApp()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.pollUntilReady(attemptsLeft: attemptsLeft - 1)
                    }
                }
            }
        }.resume()
    }

    private func openHermesApp() {
        let candidates = [
            "\(NSHomeDirectory())/Applications/Hermes.app",
            "\(Self.hermesHome())/hermes-agent/apps/desktop/release/mac-arm64/Hermes.app",
            "/Applications/Hermes.app",
        ]
        guard let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path),
                                           configuration: config,
                                           completionHandler: nil)
    }

    // ── right-click: put both apps down, reclaim their RAM now ──
    private func sleep() {
        let ids = [Self.hermesBundleID, Self.ollamaBundleID]
        let apps = ids.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }

        // Ask nicely first (lets Hermes save state). Ollama.app has shown it
        // can swallow a graceful quit with no visible confirmation UI to
        // click through, so anything still alive after a couple seconds
        // gets force-terminated rather than leaving a phantom quit pending.
        for app in apps { app.terminate() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            for app in apps where !app.isTerminated {
                app.forceTerminate()
            }
        }
        apply(.idle)
    }

    private func isRunning(bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    /// Ask Ollama to hold the configured model in memory so the first message
    /// in Hermes doesn't pay the cold-load cost.
    private func preloadModel() {
        let model = Self.configuredModel()
        guard var request = URLRequest.jsonPost("http://127.0.0.1:11434/api/generate") else { return }
        // Ollama's default 5m idle unload: the model comes up when you click and
        // releases its ~22GB shortly after you stop using it.
        let body: [String: Any] = ["model": model, "prompt": "", "keep_alive": "5m"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    /// Resolves HERMES_HOME the same way Hermes itself does: env var first
    /// (GUI apps get this from `launchctl setenv`, set once at login by
    /// local.llm.hermes-env.plist), falling back to the platform default.
    private static func hermesHome() -> String {
        if let env = ProcessInfo.processInfo.environment["HERMES_HOME"], !env.isEmpty {
            return env
        }
        return "\(NSHomeDirectory())/.hermes"
    }

    /// Reads model.default out of Hermes's config.yaml so the widget follows
    /// whatever Hermes itself is set to.
    private static func configuredModel() -> String {
        let fallback = "qwen3.6-moe-64k"
        let path = "\(Self.hermesHome())/config.yaml"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return fallback }

        var inModelSection = false
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.hasPrefix("model:") { inModelSection = true; continue }
            // A new top-level key ends the model block.
            if inModelSection, let first = line.first, !first.isWhitespace, line.contains(":") {
                break
            }
            if inModelSection {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("default:") else { continue }
                let value = trimmed.dropFirst("default:".count)
                    .trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
                if !value.isEmpty { return value }
            }
        }
        return fallback
    }

    // ── state detection ─────────────────────────────────────
    private func refresh() {
        // Mid-wake, `wake()` is already driving the face (loading/error) —
        // don't let a stale poll from before the click stomp on that.
        guard !waking else { return }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:11434/api/ps")!)
        request.timeoutInterval = 1.5

        URLSession.shared.dataTask(with: request) { [weak self] data, _, err in
            guard let self else { return }

            // Ollama unreachable: asleep by design (or between wake attempts),
            // not a failure — idle, same as any other resting state.
            guard err == nil, let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else {
                DispatchQueue.main.async { self.apply(.idle) }
                return
            }

            let serverBusy = Self.llamaServerCPU()
            let state: FaceState
            if models.isEmpty {
                // A running server with no model listed means weights are loading.
                state = serverBusy == nil ? .idle : .loading
            } else {
                // Inference runs on the GPU, so llama-server's CPU stays low even
                // while generating — measured 0.3% idle vs ~4% mid-generation.
                state = (serverBusy ?? 0) > 1.5 ? .thinking : .listening
            }
            DispatchQueue.main.async { self.apply(state) }
        }.resume()
    }

    /// CPU% of llama-server, or nil when it isn't running.
    private static func llamaServerCPU() -> Double? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-Ao", "pcpu,comm"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        guard (try? task.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let out = String(data: data, encoding: .utf8) else { return nil }
        for line in out.split(separator: "\n") where line.contains("llama-server") {
            let cpu = line.trimmingCharacters(in: .whitespaces)
                .split(separator: " ").first.flatMap { Double($0) }
            if let cpu { return cpu }
        }
        return nil
    }

    private func apply(_ state: FaceState) {
        guard state != current else { return }
        current = state
        guard ready else { pending = state; return }
        webView.evaluateJavaScript("window.setFaceState('\(state.rawValue)')")
    }
}

extension AppDelegate: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ready = true
        if let pending {
            webView.evaluateJavaScript("window.setFaceState('\(pending.rawValue)')")
            self.pending = nil
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // no Dock icon, no app switcher
app.run()

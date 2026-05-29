import AppKit
import SwiftUI

private enum AppRuntime {
    static var delegate: AppDelegate?
}

@main
enum LatencyGraphLauncher {
    static func main() {
        let runtimePlan = RuntimeFeaturePlan.current
        if runtimePlan.usesSwiftUIAppLifecycle, #available(macOS 13.0, *) {
            NativeLatencyGraphApp.main()
        } else {
            MainActor.assumeIsolated {
                let app = NSApplication.shared
                let delegate = AppDelegate()
                AppRuntime.delegate = delegate
                app.delegate = delegate
                app.setActivationPolicy(.regular)
                app.run()
            }
        }
    }
}

@available(macOS 13.0, *)
struct NativeLatencyGraphApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            NativeModernContentView()
                .environmentObject(model)
        }

        MenuBarExtra {
            MenuBarPanel()
                .environmentObject(model)
        } label: {
            Label(menuBarTitle, systemImage: "waveform.path.ecg")
        }

        Settings {
            NativeModernContentView()
                .environmentObject(model)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Latency Graph for ClashX Meta") {
                    AboutPanelPresenter.show()
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private var menuBarTitle: String {
        let latency = model.stats(for: model.monitoredProxyNames).lastLatency
        if let latency {
            return "Latency Graph \(latency)ms"
        }
        return "Latency Graph --"
    }
}

enum AboutPanelPresenter {
    @MainActor
    static func show() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.6.1"
        let build = info?["CFBundleVersion"] as? String ?? "17"
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "Latency Graph for ClashX Meta",
            .applicationVersion: version,
            .version: build,
            .credits: NSAttributedString(
                string: "Node latency monitoring for ClashX Meta.\nCSV export, SQLite retention, Charts rendering, and packaged DMG builds.",
                attributes: [.font: NSFont.systemFont(ofSize: 12)]
            )
        ])
    }
}

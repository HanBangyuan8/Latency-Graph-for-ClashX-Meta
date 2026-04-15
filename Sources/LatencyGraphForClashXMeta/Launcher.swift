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
    }

    private var menuBarTitle: String {
        let latency = model.stats(for: model.monitoredProxyNames).lastLatency
        if let latency {
            return "Latency Graph \(latency)ms"
        }
        return "Latency Graph --"
    }
}

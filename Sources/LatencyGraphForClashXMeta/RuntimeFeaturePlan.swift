import Foundation

struct RuntimeFeaturePlan {
    let profile: RuntimeOptimizationProfile

    static var current: RuntimeFeaturePlan {
        RuntimeFeaturePlan(profile: .current)
    }

    var sourceBranchName: String {
        switch profile.osFamily {
        case .macOS15OrNewer:
            return "macOS15Native"
        case .macOS13Or14:
            return "macOS13Native"
        case .macOS12:
            return "macOS12Compatibility"
        case .macOS1015Or11:
            return "macOSLegacyFixedSidebar"
        }
    }

    var usesSwiftUIAppLifecycle: Bool {
        profile.osFamily == .macOS13Or14 || profile.osFamily == .macOS15OrNewer
    }

    var usesMenuBarExtraScene: Bool {
        usesSwiftUIAppLifecycle
    }

    var allowsSidebarCollapse: Bool {
        profile.osFamily != .macOS1015Or11
    }

    var usesAdvancedTransitions: Bool {
        switch profile.osFamily {
        case .macOS15OrNewer:
            return true
        case .macOS13Or14:
            return profile.usesAppleSilicon
        case .macOS12, .macOS1015Or11:
            return false
        }
    }

    var probeConcurrencyLimit: Int {
        profile.probeConcurrencyLimit
    }

    var sampleConcurrencyLimit: Int {
        switch (profile.chipFamily, profile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer): return 5
        case (.appleSilicon, .macOS13Or14): return 4
        case (.appleSilicon, .macOS12): return 3
        case (.appleSilicon, .macOS1015Or11): return 2
        case (.intel, .macOS15OrNewer): return 3
        case (.intel, .macOS13Or14): return 3
        case (.intel, .macOS12): return 2
        case (.intel, .macOS1015Or11): return 1
        }
    }

    var persistenceDebounceNanoseconds: UInt64 {
        switch profile.osFamily {
        case .macOS15OrNewer:
            return 120_000_000
        case .macOS13Or14:
            return 180_000_000
        case .macOS12:
            return 260_000_000
        case .macOS1015Or11:
            return 420_000_000
        }
    }

    var retentionDays: Int {
        switch (profile.chipFamily, profile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer): return 45
        case (.appleSilicon, .macOS13Or14): return 35
        case (.appleSilicon, .macOS12): return 30
        case (.appleSilicon, .macOS1015Or11): return 21
        case (.intel, .macOS15OrNewer): return 30
        case (.intel, .macOS13Or14): return 30
        case (.intel, .macOS12): return 21
        case (.intel, .macOS1015Or11): return 14
        }
    }
}

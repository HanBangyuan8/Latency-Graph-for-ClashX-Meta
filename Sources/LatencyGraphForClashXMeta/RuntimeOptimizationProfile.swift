import Foundation
import SwiftUI

enum RuntimeChipFamily: String {
    case appleSilicon
    case intel
}

enum RuntimeOSFamily: String {
    case macOS1015Or11
    case macOS12
    case macOS13Or14
    case macOS15OrNewer
}

struct RuntimeOptimizationProfile {
    let chipFamily: RuntimeChipFamily
    let osFamily: RuntimeOSFamily

    static var current: RuntimeOptimizationProfile {
        RuntimeOptimizationProfile(
            chipFamily: detectedChipFamily,
            osFamily: detectedOSFamily
        )
    }

    private static var detectedChipFamily: RuntimeChipFamily {
        #if arch(arm64)
        return .appleSilicon
        #elseif arch(x86_64)
        return .intel
        #else
        return .intel
        #endif
    }

    private static var detectedOSFamily: RuntimeOSFamily {
        if #available(macOS 15.0, *) {
            return .macOS15OrNewer
        }
        if #available(macOS 13.0, *) {
            return .macOS13Or14
        }
        if #available(macOS 12.0, *) {
            return .macOS12
        }
        return .macOS1015Or11
    }

    var isModernSystem: Bool {
        osFamily == .macOS13Or14 || osFamily == .macOS15OrNewer
    }

    var isSequoiaOrNewer: Bool {
        osFamily == .macOS15OrNewer
    }

    var usesAppleSilicon: Bool {
        chipFamily == .appleSilicon
    }

    var nodeChartBudgetSmallRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 640
        case (.appleSilicon, .macOS13Or14): 520
        case (.appleSilicon, .macOS12): 460
        case (.appleSilicon, .macOS1015Or11): 320
        case (.intel, .macOS15OrNewer): 480
        case (.intel, .macOS13Or14): 420
        case (.intel, .macOS12): 340
        case (.intel, .macOS1015Or11): 260
        }
    }

    var nodeChartBudgetDayRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 900
        case (.appleSilicon, .macOS13Or14): 760
        case (.appleSilicon, .macOS12): 640
        case (.appleSilicon, .macOS1015Or11): 420
        case (.intel, .macOS15OrNewer): 660
        case (.intel, .macOS13Or14): 560
        case (.intel, .macOS12): 440
        case (.intel, .macOS1015Or11): 320
        }
    }

    var nodeChartBudgetWeekRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_080
        case (.appleSilicon, .macOS13Or14): 920
        case (.appleSilicon, .macOS12): 760
        case (.appleSilicon, .macOS1015Or11): 480
        case (.intel, .macOS15OrNewer): 760
        case (.intel, .macOS13Or14): 660
        case (.intel, .macOS12): 520
        case (.intel, .macOS1015Or11): 360
        }
    }

    var nodeChartBudgetLongRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_320
        case (.appleSilicon, .macOS13Or14): 1_120
        case (.appleSilicon, .macOS12): 880
        case (.appleSilicon, .macOS1015Or11): 560
        case (.intel, .macOS15OrNewer): 860
        case (.intel, .macOS13Or14): 760
        case (.intel, .macOS12): 600
        case (.intel, .macOS1015Or11): 420
        }
    }

    var overviewBasePointsSmallRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_150
        case (.appleSilicon, .macOS13Or14): 950
        case (.appleSilicon, .macOS12): 780
        case (.appleSilicon, .macOS1015Or11): 420
        case (.intel, .macOS15OrNewer): 820
        case (.intel, .macOS13Or14): 700
        case (.intel, .macOS12): 560
        case (.intel, .macOS1015Or11): 320
        }
    }

    var overviewBasePointsDayRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_350
        case (.appleSilicon, .macOS13Or14): 1_150
        case (.appleSilicon, .macOS12): 900
        case (.appleSilicon, .macOS1015Or11): 500
        case (.intel, .macOS15OrNewer): 940
        case (.intel, .macOS13Or14): 800
        case (.intel, .macOS12): 620
        case (.intel, .macOS1015Or11): 380
        }
    }

    var overviewBasePointsWeekRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_560
        case (.appleSilicon, .macOS13Or14): 1_300
        case (.appleSilicon, .macOS12): 1_000
        case (.appleSilicon, .macOS1015Or11): 560
        case (.intel, .macOS15OrNewer): 1_050
        case (.intel, .macOS13Or14): 900
        case (.intel, .macOS12): 700
        case (.intel, .macOS1015Or11): 420
        }
    }

    var overviewBasePointsLongRange: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 1_820
        case (.appleSilicon, .macOS13Or14): 1_500
        case (.appleSilicon, .macOS12): 1_080
        case (.appleSilicon, .macOS1015Or11): 640
        case (.intel, .macOS15OrNewer): 1_120
        case (.intel, .macOS13Or14): 960
        case (.intel, .macOS12): 740
        case (.intel, .macOS1015Or11): 480
        }
    }

    var overviewTotalPointCeiling: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 12_000
        case (.appleSilicon, .macOS13Or14): 10_000
        case (.appleSilicon, .macOS12): 7_200
        case (.appleSilicon, .macOS1015Or11): 3_200
        case (.intel, .macOS15OrNewer): 7_200
        case (.intel, .macOS13Or14): 6_400
        case (.intel, .macOS12): 4_800
        case (.intel, .macOS1015Or11): 2_400
        }
    }

    var minimumOverviewPointsPerSeries: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 640
        case (.appleSilicon, .macOS13Or14): 520
        case (.appleSilicon, .macOS12): 420
        case (.appleSilicon, .macOS1015Or11): 180
        case (.intel, .macOS15OrNewer): 420
        case (.intel, .macOS13Or14): 360
        case (.intel, .macOS12): 300
        case (.intel, .macOS1015Or11): 140
        }
    }

    var probeConcurrencyLimit: Int {
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer): 18
        case (.appleSilicon, .macOS13Or14): 16
        case (.appleSilicon, .macOS12): 10
        case (.appleSilicon, .macOS1015Or11): 5
        case (.intel, .macOS15OrNewer): 10
        case (.intel, .macOS13Or14): 8
        case (.intel, .macOS12): 5
        case (.intel, .macOS1015Or11): 3
        }
    }

    func pageAnimation(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        switch (chipFamily, osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interactiveSpring(response: 0.62, dampingFraction: 0.80, blendDuration: 0.12)
        case (.appleSilicon, .macOS13Or14):
            return MotionTokens.page
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.50, dampingFraction: 0.86, blendDuration: 0.08)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.20)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.50, dampingFraction: 0.86, blendDuration: 0.08)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.06)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.22)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.16)
        }
    }
}

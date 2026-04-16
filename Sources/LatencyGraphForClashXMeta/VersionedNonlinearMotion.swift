import SwiftUI

struct VersionedMotionProfile {
    let runtimeProfile: RuntimeOptimizationProfile

    static var current: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: .current)
    }

    var startupAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.78, stiffness: 132, damping: 15, initialVelocity: 0.22)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.86, stiffness: 116, damping: 16, initialVelocity: 0.16)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.58, dampingFraction: 0.86, blendDuration: 0.10)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.34)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.54, dampingFraction: 0.88, blendDuration: 0.08)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.50, dampingFraction: 0.90, blendDuration: 0.08)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.30)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.22)
        }
    }

    var pageSwitchAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.70, stiffness: 148, damping: 14.5, initialVelocity: 0.28)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.82, stiffness: 124, damping: 15.5, initialVelocity: 0.20)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.58, dampingFraction: 0.84, blendDuration: 0.08)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.28)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.50, dampingFraction: 0.88, blendDuration: 0.08)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.46, dampingFraction: 0.90, blendDuration: 0.06)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.26)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.18)
        }
    }

    var pageTapAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.58, stiffness: 190, damping: 16, initialVelocity: 0.35)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.66, stiffness: 166, damping: 17, initialVelocity: 0.24)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.34, dampingFraction: 0.78, blendDuration: 0.05)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.16)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.30, dampingFraction: 0.82, blendDuration: 0.04)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.28, dampingFraction: 0.84, blendDuration: 0.04)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.14)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.10)
        }
    }

    var settleAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.62, stiffness: 210, damping: 20, initialVelocity: 0.18)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.70, stiffness: 184, damping: 21, initialVelocity: 0.14)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.34, dampingFraction: 0.88, blendDuration: 0.04)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.14)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.32, dampingFraction: 0.90, blendDuration: 0.04)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.30, dampingFraction: 0.92, blendDuration: 0.04)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.12)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.08)
        }
    }

    var anticipatoryAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .timingCurve(0.22, 0.82, 0.18, 1.00, duration: 0.22)
        case (.appleSilicon, .macOS13Or14):
            return .timingCurve(0.24, 0.78, 0.20, 1.00, duration: 0.20)
        case (.appleSilicon, .macOS12):
            return .timingCurve(0.28, 0.70, 0.24, 1.00, duration: 0.18)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.12)
        case (.intel, .macOS15OrNewer):
            return .timingCurve(0.28, 0.76, 0.24, 1.00, duration: 0.18)
        case (.intel, .macOS13Or14):
            return .timingCurve(0.30, 0.72, 0.26, 1.00, duration: 0.16)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.12)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.08)
        }
    }

    var componentAppearAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.74, stiffness: 168, damping: 19, initialVelocity: 0.10)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.82, stiffness: 146, damping: 20, initialVelocity: 0.08)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.42, dampingFraction: 0.90, blendDuration: 0.05)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.20)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.38, dampingFraction: 0.92, blendDuration: 0.04)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.36, dampingFraction: 0.93, blendDuration: 0.04)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.18)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.14)
        }
    }

    var chartAppearAnimation: Animation {
        switch (runtimeProfile.chipFamily, runtimeProfile.osFamily) {
        case (.appleSilicon, .macOS15OrNewer):
            return .interpolatingSpring(mass: 0.92, stiffness: 128, damping: 24, initialVelocity: 0.04)
        case (.appleSilicon, .macOS13Or14):
            return .interpolatingSpring(mass: 0.98, stiffness: 116, damping: 25, initialVelocity: 0.03)
        case (.appleSilicon, .macOS12):
            return .interactiveSpring(response: 0.46, dampingFraction: 0.94, blendDuration: 0.04)
        case (.appleSilicon, .macOS1015Or11):
            return .easeOut(duration: 0.18)
        case (.intel, .macOS15OrNewer):
            return .interactiveSpring(response: 0.42, dampingFraction: 0.95, blendDuration: 0.04)
        case (.intel, .macOS13Or14):
            return .interactiveSpring(response: 0.40, dampingFraction: 0.96, blendDuration: 0.04)
        case (.intel, .macOS12):
            return .easeOut(duration: 0.16)
        case (.intel, .macOS1015Or11):
            return .easeOut(duration: 0.12)
        }
    }

    var startupOffset: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 22
        case .macOS13Or14: return 18
        case .macOS12: return 12
        case .macOS1015Or11: return 8
        }
    }

    var pageOffset: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 28
        case .macOS13Or14: return 24
        case .macOS12: return 18
        case .macOS1015Or11: return 10
        }
    }

    var pageScale: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 0.990
        case .macOS13Or14: return 0.992
        case .macOS12: return 0.995
        case .macOS1015Or11: return 0.998
        }
    }

    var componentOffset: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 10
        case .macOS13Or14: return 9
        case .macOS12: return 7
        case .macOS1015Or11: return 5
        }
    }

    var chartOffset: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 7
        case .macOS13Or14: return 6
        case .macOS12: return 5
        case .macOS1015Or11: return 3
        }
    }

    var tapScale: CGFloat {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 0.968
        case .macOS13Or14: return 0.974
        case .macOS12: return 0.982
        case .macOS1015Or11: return 0.990
        }
    }

    var startupSettleDelay: UInt64 {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 180_000_000
        case .macOS13Or14: return 160_000_000
        case .macOS12: return 130_000_000
        case .macOS1015Or11: return 85_000_000
        }
    }

    var pageResetDelay: UInt64 {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 24_000_000
        case .macOS13Or14: return 22_000_000
        case .macOS12: return 18_000_000
        case .macOS1015Or11: return 10_000_000
        }
    }

    var pageSettleDelay: UInt64 {
        switch runtimeProfile.osFamily {
        case .macOS15OrNewer: return 170_000_000
        case .macOS13Or14: return 145_000_000
        case .macOS12: return 115_000_000
        case .macOS1015Or11: return 70_000_000
        }
    }
}

private enum VersionedStartupPhase {
    case hidden
    case revealed
    case settled

    var opacity: Double {
        switch self {
        case .hidden: return 0
        case .revealed: return 0.98
        case .settled: return 1
        }
    }
}

private enum VersionedPageSwitchPhase {
    case settled
    case entering
    case resolving

    var opacity: Double {
        switch self {
        case .settled: return 1
        case .entering: return 0
        case .resolving: return 0.98
        }
    }
}

private enum VersionedComponentPhase {
    case hidden
    case visible
}

@available(macOS 12.0, *)
struct VersionedStartupMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: VersionedStartupPhase = .hidden
    let profile: VersionedMotionProfile
    let delay: Double

    private var startupScale: CGFloat {
        switch phase {
        case .hidden: return profile.pageScale
        case .revealed: return 1.006
        case .settled: return 1
        }
    }

    private var startupOffset: CGFloat {
        switch phase {
        case .hidden: return profile.startupOffset
        case .revealed: return -profile.startupOffset * 0.08
        case .settled: return 0
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : phase.opacity)
            .offset(y: reduceMotion ? 0 : startupOffset)
            .scaleEffect(reduceMotion ? 1 : startupScale, anchor: .top)
            .onAppear {
                guard phase == .hidden else { return }
                withAnimation(reduceMotion ? nil : profile.startupAnimation.delay(delay)) {
                    phase = .revealed
                }
                guard !reduceMotion else {
                    phase = .settled
                    return
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: profile.startupSettleDelay)
                    withAnimation(profile.settleAnimation) {
                        phase = .settled
                    }
                }
            }
    }
}

@available(macOS 12.0, *)
struct VersionedPageSwitchMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: VersionedPageSwitchPhase = .settled
    let profile: VersionedMotionProfile
    let pageID: String
    let direction: PageNavigationDirection

    private var signedOffset: CGFloat {
        switch direction {
        case .upward: return -profile.pageOffset
        case .downward: return profile.pageOffset
        case .unchanged: return profile.pageOffset * 0.35
        }
    }

    private var resolvedOffset: CGFloat {
        switch phase {
        case .settled: return 0
        case .entering: return signedOffset
        case .resolving: return -signedOffset * 0.06
        }
    }

    private var resolvedScale: CGFloat {
        switch phase {
        case .settled: return 1
        case .entering: return profile.pageScale
        case .resolving: return 1.004
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : phase.opacity)
            .offset(y: reduceMotion ? 0 : resolvedOffset)
            .scaleEffect(reduceMotion ? 1 : resolvedScale, anchor: direction == .upward ? .top : .bottom)
            .onAppear {
                restart()
            }
            .onChange(of: pageID) { _ in
                restart()
            }
    }

    private func restart() {
        guard !reduceMotion else {
            phase = .settled
            return
        }
        var resetTransaction = Transaction()
        resetTransaction.disablesAnimations = true
        withTransaction(resetTransaction) {
            phase = .entering
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: profile.pageResetDelay)
            withAnimation(profile.pageSwitchAnimation) {
                phase = .resolving
            }
            try? await Task.sleep(nanoseconds: profile.pageSettleDelay)
            withAnimation(profile.settleAnimation) {
                phase = .settled
            }
        }
    }
}

@available(macOS 12.0, *)
struct VersionedComponentAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: VersionedComponentPhase = .hidden
    let profile: VersionedMotionProfile
    let pageID: String
    let direction: PageNavigationDirection
    let isChart: Bool

    private var initialOffset: CGFloat {
        let magnitude = isChart ? profile.chartOffset : profile.componentOffset
        switch direction {
        case .upward: return -magnitude
        case .downward: return magnitude
        case .unchanged: return magnitude * 0.5
        }
    }

    private var animation: Animation {
        isChart ? profile.chartAppearAnimation : profile.componentAppearAnimation
    }

    func body(content: Content) -> some View {
        content
            .opacity(phase == .visible || reduceMotion ? 1 : 0)
            .offset(y: phase == .visible || reduceMotion ? 0 : initialOffset)
            .scaleEffect(phase == .visible || reduceMotion ? 1 : (isChart ? 0.998 : 0.996), anchor: .center)
            .onAppear {
                restart()
            }
            .onChange(of: pageID) { _ in
                restart()
            }
    }

    private func restart() {
        guard !reduceMotion else {
            phase = .visible
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            phase = .hidden
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 8_000_000)
            withAnimation(animation) {
                phase = .visible
            }
        }
    }
}

@available(macOS 12.0, *)
struct VersionedPagePressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isSelected: Bool
    let accentColor: Color
    let profile: VersionedMotionProfile

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.14) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isSelected ? accentColor.opacity(0.18) : Color.clear, lineWidth: 1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .padding(.vertical, -8)
            .padding(.horizontal, -10)
            .scaleEffect(configuration.isPressed && !reduceMotion ? profile.tapScale : 1, anchor: .center)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : profile.pageTapAnimation, value: configuration.isPressed)
            .animation(reduceMotion ? nil : profile.pageSwitchAnimation, value: isSelected)
    }
}

struct LegacyVersionedStartupMotionModifier: ViewModifier {
    @State private var isVisible = false
    let profile: VersionedMotionProfile
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : profile.startupOffset)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(profile.startupAnimation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct LegacyVersionedPagePressButtonStyle: ButtonStyle {
    let profile: VersionedMotionProfile

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? profile.tapScale : 1)
            .opacity(configuration.isPressed ? 0.80 : 1)
            .animation(profile.pageTapAnimation, value: configuration.isPressed)
    }
}

@available(macOS 12.0, *)
extension View {
    func versionedStartupMotion(profile: VersionedMotionProfile, delay: Double = 0) -> some View {
        modifier(VersionedStartupMotionModifier(profile: profile, delay: delay))
    }

    func versionedPageSwitchMotion(profile: VersionedMotionProfile, pageID: String, direction: PageNavigationDirection) -> some View {
        modifier(VersionedPageSwitchMotionModifier(profile: profile, pageID: pageID, direction: direction))
    }

    func versionedComponentAppear(profile: VersionedMotionProfile, pageID: String, direction: PageNavigationDirection, isChart: Bool = false) -> some View {
        modifier(VersionedComponentAppearModifier(profile: profile, pageID: pageID, direction: direction, isChart: isChart))
    }
}

extension View {
    func legacyVersionedStartupMotion(profile: VersionedMotionProfile, delay: Double = 0) -> some View {
        modifier(LegacyVersionedStartupMotionModifier(profile: profile, delay: delay))
    }
}

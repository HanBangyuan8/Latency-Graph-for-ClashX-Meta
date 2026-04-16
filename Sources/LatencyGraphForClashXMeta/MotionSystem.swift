import SwiftUI

enum MotionTokens {
    static let quick: Animation = .interactiveSpring(response: 0.22, dampingFraction: 0.72, blendDuration: 0.04)
    static let soft: Animation = .interactiveSpring(response: 0.42, dampingFraction: 0.78, blendDuration: 0.08)
    static let page: Animation = .interactiveSpring(response: 0.54, dampingFraction: 0.82, blendDuration: 0.10)
    static let appear: Animation = .spring(response: 0.48, dampingFraction: 0.84, blendDuration: 0.08)
    static let hover: Animation = .interactiveSpring(response: 0.30, dampingFraction: 0.74, blendDuration: 0.04)
    static let color: Animation = .easeInOut(duration: 0.30)
    static let listSelection: Animation = .interactiveSpring(response: 0.34, dampingFraction: 0.76, blendDuration: 0.06)
    static let legacyAppear: Animation = .easeOut(duration: 0.28)
    static let legacyHover: Animation = .easeOut(duration: 0.12)
    static let legacyChart: Animation = .easeOut(duration: 0.62)
}

enum PageNavigationDirection {
    case upward
    case downward
    case unchanged

    var insertionEdge: Edge {
        switch self {
        case .upward: .top
        case .downward: .bottom
        case .unchanged: .bottom
        }
    }

    var removalEdge: Edge {
        switch self {
        case .upward: .bottom
        case .downward: .top
        case .unchanged: .top
        }
    }

    func transition(reduceMotion: Bool, intensity: MotionIntensity = .enhanced) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let insertionAnchor: UnitPoint = insertionEdge == .bottom ? .bottom : .top
        let removalAnchor: UnitPoint = removalEdge == .bottom ? .bottom : .top
        let insertionDistance: CGFloat = intensity == .enhanced ? 180 : 18
        let removalDistance: CGFloat = intensity == .enhanced ? 76 : 10
        let insertionScale: CGFloat = intensity == .enhanced ? 0.955 : 0.996
        let removalScale: CGFloat = intensity == .enhanced ? 0.982 : 0.998
        return .asymmetric(
            insertion: .offset(x: 0, y: insertionEdge == .bottom ? insertionDistance : -insertionDistance)
                .combined(with: .scale(scale: insertionScale, anchor: insertionAnchor))
                .combined(with: .opacity),
            removal: .offset(x: 0, y: removalEdge == .bottom ? removalDistance : -removalDistance)
                .combined(with: .scale(scale: removalScale, anchor: removalAnchor))
                .combined(with: .opacity)
        )
    }
}

struct LightweightPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(reduceMotion ? nil : MotionTokens.quick, value: configuration.isPressed)
    }
}

@available(macOS 12.0, *)
struct ControlButtonHoverModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(accentColor.opacity(isHovered ? 0.08 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(accentColor.opacity(isHovered ? 0.45 : 0), lineWidth: isHovered ? 1.3 : 1)
            }
            .scaleEffect(isHovered && !reduceMotion ? 1.025 : 1)
            .animation(reduceMotion ? nil : MotionTokens.hover, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct GentleAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 6)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(reduceMotion ? nil : MotionTokens.appear) {
                    isVisible = true
                }
            }
    }
}

struct LegacyAppearModifier: ViewModifier {
    @State private var isVisible = false
    let index: Int
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : distance)
            .scaleEffect(isVisible ? 1 : 0.992)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(MotionTokens.legacyAppear) {
                    isVisible = true
                }
            }
    }
}

struct LegacyInteractiveCardModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.012 : 1)
            .shadow(color: Color.black.opacity(isHovered ? 0.10 : 0.04), radius: isHovered ? 8 : 3, x: 0, y: isHovered ? 4 : 1)
            .animation(MotionTokens.legacyHover, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct LegacyButtonMotionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.76 : 1)
            .animation(MotionTokens.legacyHover, value: configuration.isPressed)
    }
}

@available(macOS 12.0, *)
struct InteractivePanelModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let cornerRadius: CGFloat
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(accentColor.opacity(isHovered ? 0.045 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentColor.opacity(isHovered ? 0.36 : 0), lineWidth: isHovered ? 1.4 : 1)
            }
            .scaleEffect(isHovered ? 1.006 : 1)
            .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0), radius: isHovered ? 8 : 0, x: 0, y: isHovered ? 3 : 0)
            .animation(reduceMotion ? nil : MotionTokens.hover, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

@available(macOS 12.0, *)
struct SettingsSolidCardModifier: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.12), lineWidth: 1)
            }
    }
}

@available(macOS 12.0, *)
struct SidebarPageButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isSelected: Bool
    let accentColor: Color

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
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : MotionTokens.listSelection, value: isSelected)
            .animation(reduceMotion ? nil : MotionTokens.quick, value: configuration.isPressed)
    }
}

@available(macOS 12.0, *)
struct SoftSectionAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let delay: Double
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : distance)
            .blur(radius: isVisible || reduceMotion ? 0 : 1.8)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(reduceMotion ? nil : MotionTokens.appear) {
                    isVisible = true
                }
            }
    }
}

@available(macOS 12.0, *)
struct StaggeredGroupAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 8)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(reduceMotion ? nil : MotionTokens.appear) {
                    isVisible = true
                }
            }
    }
}

@available(macOS 12.0, *)
struct ChartRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let direction: PageNavigationDirection
    let pageID: String

    private var initialOffset: CGFloat {
        switch direction {
        case .upward: -14
        case .downward: 14
        case .unchanged: 8
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : initialOffset)
            .onAppear {
                restartReveal()
            }
            .onChange(of: pageID) { _ in
                restartReveal()
            }
    }

    private func restartReveal() {
        guard !reduceMotion else {
            isVisible = true
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 12_000_000)
            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.92, blendDuration: 0.05)) {
                isVisible = true
            }
        }
    }
}


@available(macOS 12.0, *)
extension View {
    func gentleAppear(delay: Double = 0) -> some View {
        modifier(GentleAppearModifier(delay: delay))
    }

    func interactivePanel(cornerRadius: CGFloat = 16, accentColor: Color) -> some View {
        modifier(InteractivePanelModifier(cornerRadius: cornerRadius, accentColor: accentColor))
    }

    func softSectionAppear(delay: Double = 0, distance: CGFloat = 10) -> some View {
        modifier(SoftSectionAppearModifier(delay: delay, distance: distance))
    }

    func settingsSolidCard(accentColor: Color) -> some View {
        modifier(SettingsSolidCardModifier(accentColor: accentColor))
    }

    func controlButtonHover(accentColor: Color) -> some View {
        modifier(ControlButtonHoverModifier(accentColor: accentColor))
    }

    func staggeredGroupAppear(index: Int) -> some View {
        modifier(StaggeredGroupAppearModifier(index: index))
    }

    func chartReveal(direction: PageNavigationDirection, pageID: String) -> some View {
        modifier(ChartRevealModifier(direction: direction, pageID: pageID))
    }
}

extension View {
    func legacyAppear(index: Int = 0, distance: CGFloat = 10) -> some View {
        modifier(LegacyAppearModifier(index: index, distance: distance))
    }

    func legacyInteractiveCard() -> some View {
        modifier(LegacyInteractiveCardModifier())
    }
}

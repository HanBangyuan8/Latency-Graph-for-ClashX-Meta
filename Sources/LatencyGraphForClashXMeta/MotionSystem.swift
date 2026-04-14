import SwiftUI

enum MotionTokens {
    static let quick: Animation = .interactiveSpring(response: 0.22, dampingFraction: 0.72, blendDuration: 0.04)
    static let soft: Animation = .interactiveSpring(response: 0.42, dampingFraction: 0.78, blendDuration: 0.08)
    static let page: Animation = .interactiveSpring(response: 0.54, dampingFraction: 0.82, blendDuration: 0.10)
    static let appear: Animation = .spring(response: 0.48, dampingFraction: 0.84, blendDuration: 0.08)
    static let hover: Animation = .interactiveSpring(response: 0.30, dampingFraction: 0.74, blendDuration: 0.04)
    static let color: Animation = .easeInOut(duration: 0.30)
    static let listSelection: Animation = .interactiveSpring(response: 0.34, dampingFraction: 0.76, blendDuration: 0.06)
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

    func transition(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let insertionAnchor: UnitPoint = insertionEdge == .bottom ? .bottom : .top
        let removalAnchor: UnitPoint = removalEdge == .bottom ? .bottom : .top
        return .asymmetric(
            insertion: .move(edge: insertionEdge)
                .combined(with: .scale(scale: 0.985, anchor: insertionAnchor))
                .combined(with: .opacity),
            removal: .move(edge: removalEdge)
                .combined(with: .scale(scale: 0.992, anchor: removalAnchor))
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

struct ControlButtonHoverModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(accentColor.opacity(isHovered ? 0.22 : 0), lineWidth: 1)
            }
            .scaleEffect(isHovered && !reduceMotion ? 1.015 : 1)
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
                withAnimation(reduceMotion ? nil : MotionTokens.appear.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct InteractivePanelModifier: ViewModifier {
    @State private var isHovered = false
    let cornerRadius: CGFloat
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentColor.opacity(isHovered ? 0.18 : 0), lineWidth: 1)
            }
            .animation(.linear(duration: 0.10), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

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
                withAnimation(reduceMotion ? nil : MotionTokens.appear.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

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
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18).delay(Double(index) * 0.035)) {
                    isVisible = true
                }
            }
    }
}

struct ChartRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let direction: PageNavigationDirection
    let pageID: String

    private var initialOffset: CGFloat {
        switch direction {
        case .upward: -72
        case .downward: 72
        case .unchanged: 36
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
            try? await Task.sleep(nanoseconds: 35_000_000)
            withAnimation(.interactiveSpring(response: 0.62, dampingFraction: 0.84, blendDuration: 0.10)) {
                isVisible = true
            }
        }
    }
}

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

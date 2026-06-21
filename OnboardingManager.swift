import SwiftUI

final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    @AppStorage("onboarding_milestones") private var completedMilestonesData: String = "[]"
    private(set) var completedMilestones: Set<string> {
        get {
            guard let data = completedMilestonesData.data(using: .utf8),
                  let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return Set(ids)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue)),
               let str = String(data: data, encoding: .utf8) { completedMilestonesData = str }
        }
    }
    @Published var activeGuide: OnboardingGuide?
    @AppStorage("onboarding_shown_guides") private var shownGuidesData: String = "[]"
    private var shownGuides: Set<string> {
        get {
            guard let data = shownGuidesData.data(using: .utf8),
                  let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return Set(ids)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue)),
               let str = String(data: data, encoding: .utf8) { shownGuidesData = str }
        }
    }
    func mark(_ milestone: OnboardingMilestone) {
        var current = completedMilestones
        current.insert(milestone.id)
        completedMilestones = current
        checkForGuide()
    }
    func dismissGuide() {
        if let guide = activeGuide {
            var shown = shownGuides
            shown.insert(guide.id)
            shownGuides = shown
        }
        activeGuide = nil
    }
    private func checkForGuide() {
        let ms = completedMilestones
        if ms.contains(OnboardingMilestone.firstLaunch.id) && !ms.contains(OnboardingMilestone.firstCaseAdded.id) && !shownGuides.contains("addFirstCase") {
            activeGuide = OnboardingGuide(id: "addFirstCase", title: "从这里开始", message: "添加你的第一个案件，或者导入已有联系人。", icon: "plus.rectangle.fill", color: .tealLink)
            return
        }
        if ms.contains(OnboardingMilestone.firstCaseAdded.id) && !shownGuides.contains("discoverPeople") {
            activeGuide = OnboardingGuide(id: "discoverPeople", title: "案件里的人，都在这里", message: "切换到「人脉」标签页，看看这个案件里涉及了哪些人。", icon: "person.2.fill", color: .coralWarm)
            return
        }
        if ms.contains(OnboardingMilestone.firstHearingAdded.id) && !shownGuides.contains("calendarSync") {
            activeGuide = OnboardingGuide(id: "calendarSync", title: "开庭日期已同步", message: "这个开庭日期已自动同步到系统日历。你可以在「日历」标签页查看。", icon: "calendar.badge.checkmark", color: .statusInfo)
            return
        }
        if ms.contains(OnboardingMilestone.firstCaseClosed.id) && !shownGuides.contains("checkOverview") {
            activeGuide = OnboardingGuide(id: "checkOverview", title: "看看你的进展", message: "案件页顶部现在有统计概览了，可以看到你经手的案件数据。", icon: "chart.bar.fill", color: .statusSuccess)
            return
        }
        if ms.contains(OnboardingMilestone.firstConnectionExplored.id) && !shownGuides.contains("exploreNetwork") {
            activeGuide = OnboardingGuide(id: "exploreNetwork", title: "你的网络正在生长", message: "随着你添加更多案件和联系人，你的人脉网络会自动展开。这是「屿连」最核心的能力。", icon: "bolt.horizontal.fill", color: .tealLink)
            return
        }
    }
}

struct OnboardingGuide: Identifiable, Equatable {
    let id: String; let title: String; let message: String; let icon: String; let color: Color
}

struct OnboardingGuideView: View {
    let guide: OnboardingGuide; var onDismiss: () -> Void
    @State private var isVisible = false
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    Circle().fill(guide.color.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: guide.icon).font(.system(size: 20, weight: .semibold)).foregroundColor(guide.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(guide.title).font(.cnHeadline).foregroundColor(.textPrimary)
                    Text(guide.message).font(.cnSubhead).foregroundColor(.textSecondary).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.3)) { isVisible = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDismiss() }
                } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .medium)).foregroundColor(.textTertiary).frame(width: 28, height: 28).background(Color.surfaceCard).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.base).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
            .padding(.horizontal, Spacing.base).padding(.bottom, Spacing.lg)
            .offset(y: isVisible ? 0 : 80).opacity(isVisible ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isVisible = true } }
    }
}

struct OnboardingOverlay: ViewModifier {
    @StateObject private var onboarding = OnboardingManager.shared
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let guide = onboarding.activeGuide {
                OnboardingGuideView(guide: guide) { onboarding.dismissGuide() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func onboardingGuides() -> some View { modifier(OnboardingOverlay()) }
}

struct OnboardingProgressView: View {
    @StateObject private var onboarding = OnboardingManager.shared
    private let allMilestones = OnboardingMilestone.allCases
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            let completed = allMilestones.filter { onboarding.completedMilestones.contains($0.id) }.count
            HStack {
                Text("功能引导").font(.cnHeadline).foregroundColor(.textPrimary)
                Spacer()
                Text("\(completed)/\(allMilestones.count)").font(.cnSubhead).foregroundColor(.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.divider).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(Color.tealLink)
                        .frame(width: geo.size.width * CGFloat(completed) / CGFloat(allMilestones.count), height: 6)
                }
            }.frame(height: 6)
            ForEach(allMilestones, id: \.id) { m in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: onboarding.completedMilestones.contains(m.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(onboarding.completedMilestones.contains(m.id) ? .statusSuccess : .textTertiary)
                    Text(m.rawValue).font(.cnSubhead)
                        .foregroundColor(onboarding.completedMilestones.contains(m.id) ? .textPrimary : .textTertiary)
                }
            }
        }
    }
}
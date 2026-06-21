import SwiftUI

// MARK: - 键盘快捷键通知

extension Notification.Name {
    /// Cmd+F 键盘快捷键触发搜索聚焦
    static let islandLinkFocusSearch = Notification.Name("islandLinkFocusSearch")
}

// MARK: - 跨平台剪贴板

enum Clipboard {
    static func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}

// MARK: - iPad 拖拽传输数据

struct PersonTransferData: Codable, Transferable {
    let personID: String
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .utf8PlainText)
    }
}

// MARK: - 语义色定义

/// 屿连 IslandLink 设计系统 v2 — 语义色
extension Color {
    static let oceanDeep = Color(hex: "0D2137")
    static let tealLink = Color(hex: "00897B")
    static let coralWarm = Color(hex: "E07B5A")
    static let surfaceLight = Color("SurfaceLight")
    static let surfaceCard = Color("SurfaceCard")
    static let divider = Color("Divider")
    static let statusSuccess = Color(hex: "2E7D32")
    static let statusWarning = Color(hex: "ED6C02")
    static let statusError = Color(hex: "D32F2F")
    static let statusInfo = Color(hex: "1565C0")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
}

// MARK: - Hex 初始化器

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension PersonRoleType {
    var swiftUIColor: Color { Color(hex: colorHex) }
    var swiftUIBackground: Color { swiftUIColor.opacity(0.12) }
}

extension CaseStatus {
    var swiftUIColor: Color {
        switch self {
        case .consulting: return .statusInfo; case .retained: return .tealLink
        case .filing: return .statusInfo; case .inTrial: return .statusWarning
        case .mediated: return .statusSuccess; case .judged: return .statusSuccess
        case .enforcing: return .statusWarning; case .closed: return .textTertiary
        case .appealed: return .coralWarm
        }
    }
    var dotColor: Color { swiftUIColor }
    var backgroundColor: Color { swiftUIColor.opacity(0.12) }
}

extension EventStatus {
    var swiftUIColor: Color {
        switch self {
        case .planned: return .statusInfo; case .confirmed: return .tealLink
        case .completed: return .statusSuccess; case .cancelled: return .textTertiary
        }
    }
    var dotColor: Color { swiftUIColor }
    var backgroundColor: Color { swiftUIColor.opacity(0.12) }
}

extension EventType {
    var swiftUIColor: Color { Color(hex: colorHex) }
    var swiftUIBackground: Color { swiftUIColor.opacity(0.12) }
}

extension ActivitySignal {
    var displayColor: Color {
        switch self { case .active: return .statusSuccess; case .recent, .inactive: return .textTertiary }
    }
    var displayBackground: Color {
        switch self { case .active: return .statusSuccess.opacity(0.12); case .recent, .inactive: return .textTertiary.opacity(0.08) }
    }
    var dotColor: Color {
        switch self { case .active: return .statusSuccess; case .recent, .inactive: return .textTertiary }
    }
}

// MARK: - 字体扩展

extension Font {
    static let cnLargeTitle = Font.system(size: 34, weight: .bold)
    static let cnTitle1 = Font.system(size: 28, weight: .bold)
    static let cnTitle2 = Font.system(size: 22, weight: .semibold)
    static let cnTitle3 = Font.system(size: 20, weight: .medium)
    static let cnHeadline = Font.system(size: 17, weight: .semibold)
    static let cnBody = Font.system(size: 17)
    static let cnCallout = Font.system(size: 16)
    static let cnSubhead = Font.system(size: 15)
    static let cnFootnote = Font.system(size: 13)
    static let cnCaption1 = Font.system(size: 12)
    static let cnCaption2 = Font.system(size: 11, weight: .medium)
    static let cnMonoFootnote = Font.system(size: 13).monospacedDigit()
    static let cnMonoSubhead = Font.system(size: 15).monospacedDigit()
}

// MARK: - 间距常量

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum CornerRadius {
    static let card: CGFloat = 16
    static let nestedCard: CGFloat = 12
    static let button: CGFloat = 12
    static let tag: CGFloat = 6
    static let searchBar: CGFloat = 12
    static let sheet: CGFloat = 24
    static let modal: CGFloat = 32
    static let capsule: CGFloat = 20
}

// MARK: - 阴影 & 卡片样式

extension View {
    func cardStyle() -> some View {
        self.background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    func cardStyleSolid() -> some View {
        self.background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
    func cardShadow() -> some View { cardStyleSolid() }
}

// MARK: - 状态徽章

struct StatusBadge: View {
    let status: CaseStatus
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(status.dotColor).frame(width: 6, height: 6)
            Text(status.rawValue).font(.cnCaption2).foregroundColor(status.swiftUIColor)
        }
        .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
        .background(status.backgroundColor).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
    }
}

struct StatusCapsule: View {
    let status: CaseStatus; let count: Int; var isSelected: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(isSelected ? .white : status.dotColor).frame(width: 6, height: 6)
            Text(status.rawValue).font(.cnSubhead)
            if count > 0 { Text("\(count)").font(.cnSubhead).foregroundColor(isSelected ? .white.opacity(0.9) : .textSecondary) }
        }
        .foregroundColor(isSelected ? .white : (count > 0 ? status.swiftUIColor : .textTertiary))
        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
        .background(Capsule(style: .continuous).fill(isSelected ? status.swiftUIColor : (count > 0 ? status.swiftUIColor.opacity(0.12) : Color.surfaceCard)))
        .overlay(Capsule(style: .continuous).stroke(count > 0 || isSelected ? Color.clear : Color.divider, lineWidth: 1))
    }
}

struct EventStatusBadge: View {
    let status: EventStatus
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(status.dotColor).frame(width: 6, height: 6)
            Text(status.rawValue).font(.cnCaption2).foregroundColor(status.swiftUIColor)
        }
        .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
        .background(status.backgroundColor).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
    }
}

struct RoleTypeTag: View {
    let roleType: PersonRoleType
    var body: some View {
        Label { Text(roleType.rawValue).font(.cnCaption2) } icon: {
            Image(systemName: roleType.systemImage).font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(roleType.swiftUIColor).padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
        .background(roleType.swiftUIBackground).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
    }
}

struct EventTypeTag: View {
    let eventType: EventType
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: eventType.systemImage).font(.system(size: 10, weight: .bold))
            Text(eventType.rawValue).font(.cnCaption2)
        }
        .foregroundColor(eventType.swiftUIColor).padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
        .background(eventType.swiftUIBackground).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
    }
}

struct AvatarPlaceholder: View {
    let roleType: PersonRoleType; var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(roleType.swiftUIBackground).frame(width: size, height: size)
            Image(systemName: roleType.systemImage).font(.system(size: size * 0.45)).foregroundColor(roleType.swiftUIColor)
        }
    }
}

struct LargeAvatarPlaceholder: View {
    let roleType: PersonRoleType
    var body: some View {
        ZStack {
            Circle().fill(roleType.swiftUIBackground).frame(width: 120, height: 120)
            Image(systemName: roleType.systemImage).font(.system(size: 48)).foregroundColor(roleType.swiftUIColor)
        }
    }
}

struct TrustIndicator: View {
    let trustLevel: Int
    var body: some View {
        Group {
            if trustLevel > 0 {
                RoundedRectangle(cornerRadius: 2).fill(trustLevel == 2 ? Color.statusSuccess : Color.statusInfo).frame(width: 3)
            } else { Color.clear.frame(width: 3) }
        }
    }
}

struct ActivitySignalView: View {
    let signal: ActivitySignal?
    var body: some View {
        Group {
            if let signal = signal {
                HStack(spacing: 3) {
                    Circle().fill(signal.dotColor).frame(width: 6, height: 6)
                    Text(signal.label).font(.cnCaption2).foregroundColor(signal.displayColor)
                }
                .padding(.horizontal, Spacing.sm).padding(.vertical, 2)
                .background(signal.displayBackground).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String; var placeholder: String = "搜索..."; var onSubmit: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass").font(.system(size: 16)).foregroundColor(.textTertiary)
            TextField(placeholder, text: $text).font(.cnBody).foregroundColor(.textPrimary).onSubmit { onSubmit?() }
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
        .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.searchBar))
    }
}

struct CaseCard: View {
    let caseItem: Case
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack { StatusBadge(status: caseItem.caseStatus); Spacer() }
            Text(caseItem.name).font(.cnHeadline).foregroundColor(.textPrimary).lineLimit(2)
            if let caseNumber = caseItem.caseNumber {
                Text(caseNumber).font(.cnMonoFootnote).foregroundColor(.textSecondary)
            }
            HStack(spacing: Spacing.base) {
                if let court = caseItem.court {
                    HStack(spacing: Spacing.xs) { Image(systemName: "building.2").font(.system(size: 11)); Text(court) }
                }
                HStack(spacing: Spacing.xs) { Image(systemName: "person.2").font(.system(size: 11)); Text("\(caseItem.personCount)人") }
                if let next = caseItem.nextEvent {
                    HStack(spacing: Spacing.xs) { Image(systemName: "calendar").font(.system(size: 11)); Text(next.date.formatted(.dateTime.month(.abbreviated).day())) }
                }
                Spacer()
            }
            .font(.cnCaption1).foregroundColor(.textTertiary)
        }
        .padding(Spacing.base).cardStyleSolid()
    }
}

struct PersonRow: View {
    let person: Person; var showActivity: Bool = true
    private var primaryRole: PersonRoleType { person.roleTypes.first ?? .other }
    var body: some View {
        HStack(spacing: 0) {
            TrustIndicator(trustLevel: person.trustLevelRaw).padding(.trailing, Spacing.md)
            AvatarPlaceholder(roleType: primaryRole, size: 40).padding(.trailing, Spacing.md)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name).font(.cnHeadline).foregroundColor(.textPrimary)
                HStack(spacing: 4) {
                    Text(primaryRole.rawValue).font(.cnCaption1).foregroundColor(primaryRole.swiftUIColor)
                    Text("·").foregroundColor(.textTertiary)
                    Text("\(person.caseCount)案").font(.cnCaption1).foregroundColor(.textSecondary)
                }
            }
            Spacer()
            if showActivity, let signal = person.activitySignal { ActivitySignalView(signal: signal) }
        }
        .padding(.vertical, Spacing.md).padding(.horizontal, Spacing.base)
        .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card)).cardShadow()
        .onDrag { NSItemProvider(object: person.id as NSString) }
    }
}

struct EventCard: View {
    let event: Event
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) { EventStatusBadge(status: event.status); EventTypeTag(eventType: event.eventType); Spacer() }
            Text(event.title).font(.cnHeadline).foregroundColor(.textPrimary).lineLimit(2)
            if let date = event.date {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.tealLink)
                    Text(date.formatted(date: .abbreviated, time: event.isAllDay ? .omitted : .shortened))
                        .font(.cnCaption1).foregroundColor(.textSecondary)
                }
            }
            if let location = event.location, !location.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 12)).foregroundColor(.coralWarm)
                    Text(location).font(.cnCaption1).foregroundColor(.textSecondary).lineLimit(1)
                }
            }
            if !event.participants.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "person.2").font(.system(size: 10))
                    Text(event.participants.prefix(3).map(\.name).joined(separator: "、")).font(.cnCaption2).lineLimit(1)
                }
                .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.base).cardStyleSolid()
    }
}

struct RoleGroupSection: View {
    let groupedPersons: [(PersonRoleType, [(role: String, persons: [CasePerson])])]
    var onPersonTap: ((Person) -> Void)? = nil
    @State private var expandedSections: Set<string> = []

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(groupedPersons, id: \.0.rawValue) { roleType, specificGroups in
                roleGroupCard(roleType: roleType, specificGroups: specificGroups)
            }
        }
    }

    @ViewBuilder
    private func roleGroupCard(roleType: PersonRoleType, specificGroups: [(role: String, persons: [CasePerson])]) -> some View {
        let sectionKey = roleType.rawValue; let isExpanded = expandedSections.contains(sectionKey)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded { expandedSections.remove(sectionKey) } else { expandedSections.insert(sectionKey) }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: roleType.systemImage).font(.system(size: 16, weight: .semibold)).foregroundColor(roleType.swiftUIColor)
                    Text(roleType.rawValue).font(.cnTitle3).foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(specificGroups.flatMap(\.persons).count)人").font(.cnSubhead).foregroundColor(.textTertiary)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.textTertiary)
                }
                .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(Color.divider)
                    ForEach(specificGroups, id: \.role) { role, persons in
                        ForEach(persons, id: \.id) { cp in
                            if let person = cp.person {
                                Button { onPersonTap?(person) } label: {
                                    HStack(spacing: Spacing.md) {
                                        if let primaryRole = person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 24) }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(person.name).font(.cnHeadline).foregroundColor(.textPrimary)
                                            Text(cp.role).font(.cnCaption1).foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                        if let org = person.org { Text(org).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1).frame(maxWidth: 100, alignment: .trailing) }
                                    }
                                    .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.divider).padding(.leading, Spacing.xxl * 2)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard)).cardShadow()
    }
}

struct QuickDatePicker: View {
    @Binding var date: Date; @Binding var hasDate: Bool; var isAllDay: Bool = true
    private let calendar = Calendar.current

    private enum QuickOption: String, CaseIterable, Identifiable {
        case today = "今天"; case tomorrow = "明天"; case nextMonday = "下周一"; case twoWeeks = "两周后"; case custom = "自定义"
        var id: String { rawValue }
        func date(from base: Date, calendar: Calendar) -> Date? {
            switch self {
            case .today: return base; case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: base)
            case .nextMonday:
                var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
                comps.weekday = 2; comps.weekOfYear? += 1; return calendar.date(from: comps)
            case .twoWeeks: return calendar.date(byAdding: .day, value: 14, to: base)
            case .custom: return nil
            }
        }
        func matches(_ target: Date, calendar: Calendar) -> Bool {
            guard self != .custom else { return false }
            if self == .today { return calendar.isDateInToday(target) }
            if self == .tomorrow { return calendar.isDateInTomorrow(target) }
            guard let candidate = date(from: Date(), calendar: calendar) else { return false }
            return calendar.isDate(candidate, inSameDayAs: target)
        }
    }

    @State private var selectedQuick: QuickOption?
    @State private var showCustomPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(QuickOption.allCases) { option in
                        Button { selectQuickOption(option) } label: {
                            Text(option.rawValue).font(.cnSubhead).fontWeight(isQuickSelected(option) ? .semibold : .regular)
                                .foregroundColor(isQuickSelected(option) ? .white : .textSecondary)
                                .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                                .background(Capsule(style: .continuous).fill(isQuickSelected(option) ? Color.tealLink : Color.surfaceCard))
                                .overlay(Capsule(style: .continuous).stroke(isQuickSelected(option) ? Color.clear : Color.divider, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if showCustomPicker {
                DatePicker(isAllDay ? "选择日期" : "选择日期时间", selection: $date, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    .datePickerStyle(.graphical).padding(.top, Spacing.sm)
            }
        }
        .onAppear { if hasDate { updateQuickFromDate() } }
    }

    private func selectQuickOption(_ option: QuickOption) {
        if option == .custom { selectedQuick = .custom; showCustomPicker = true; hasDate = true }
        else if let newDate = option.date(from: Date(), calendar: calendar) { selectedQuick = option; date = newDate; hasDate = true; showCustomPicker = false }
    }
    private func isQuickSelected(_ option: QuickOption) -> Bool {
        if option == .custom { return showCustomPicker }
        if !hasDate { return false }
        return option.matches(date, calendar: calendar)
    }
    private func updateQuickFromDate() {
        for option in QuickOption.allCases where option != .custom {
            if option.matches(date, calendar: calendar) { selectedQuick = option; showCustomPicker = false; return }
        }
        selectedQuick = nil; showCustomPicker = true
    }
}

// MARK: - View Modifiers

struct StaggerEntranceModifier: ViewModifier {
    let index: Int; let staggerDelay: Double = 0.04
    @State private var isVisible = false
    func body(content: Content) -> some View {
        content.opacity(isVisible ? 1 : 0).offset(y: isVisible ? 0 : 12)
            .animation(.easeOut(duration: 0.25).delay(Double(index) * staggerDelay), value: isVisible)
            .onAppear { isVisible = true }
    }
}

struct SearchFocusAnimationModifier: ViewModifier {
    let isFocused: Bool
    func body(content: Content) -> some View {
        content.opacity(isFocused ? 1 : 0).offset(y: isFocused ? 0 : 8)
            .animation(.easeOut(duration: 0.25), value: isFocused)
    }
}

extension View {
    func staggerEntrance(index: Int) -> some View { modifier(StaggerEntranceModifier(index: index)) }
    func searchFocusAnimation(isFocused: Bool) -> some View { modifier(SearchFocusAnimationModifier(isFocused: isFocused)) }
}

// MARK: - 预设数据

#if DEBUG
enum PreviewSampleData {
    static var container: ModelContainer = {
        do {
            let schema = Schema([
                Person.self, Case.self, CasePerson.self, CaseEvent.self, CaseDocument.self, CaseNote.self,
                Tag.self, Event.self, EventPerson.self, EventCase.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            PreviewData.makeSampleData(container: container)
            return container
        } catch { fatalError("预览 ModelContainer 创建失败: \(error)") }
    }()
}
#endif
import SwiftUI
import SwiftData

struct PersonConnectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let personA: Person
    let personB: Person
    @State private var sharedCases: [Case] = []
    @State private var sharedEvents: [Event] = []
    @State private var mutualPersons: [Person] = []
    @State private var earliestDate: Date?
    @State private var latestDate: Date?
    @State private var allPersonsCache: [Person] = []
    @State private var connectionSummary: String = ""
    @State private var personBOtherConnections: [(person: Person, sharedCount: Int)] = []
    @State private var showDepthTwo = false
    @State private var personBDepthTwoConnections: [(person: Person, sharedCount: Int)] = []
    @State private var secondaryNavA: PersistentIdentifier?
    @State private var secondaryNavB: PersistentIdentifier?
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                connectionHeader
                if !connectionSummary.isEmpty { connectionSummaryCard }
                if !personBOtherConnections.isEmpty { alsoConnectedPanel }
                if earliestDate != nil || latestDate != nil { interactionTimelineCard }
                if !sharedCases.isEmpty { sharedCasesSection }
                if !sharedEvents.isEmpty { sharedEventsSection }
                if !mutualPersons.isEmpty { mutualConnectionsSection }
                if !personBDepthTwoConnections.isEmpty { depthTwoConnectionsSection }
                if sharedCases.isEmpty && sharedEvents.isEmpty { emptyConnectionState }
            }.padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md).padding(.bottom, Spacing.xxl + Spacing.xxl)
        }.background(Color.surfaceLight).navigationTitle("你们之间").navigationBarTitleDisplayMode(.inline).onAppear { loadConnectionData() }
        .navigationDestination(isPresented: Binding(get: { secondaryNavA != nil && secondaryNavB != nil }, set: { if !$0 { secondaryNavA = nil; secondaryNavB = nil } })) {
            if let idA = secondaryNavA, let idB = secondaryNavB, let pA = allPersonsCache.first(where: { $0.persistentModelID == idA }), let pB = allPersonsCache.first(where: { $0.persistentModelID == idB }) { PersonConnectionView(personA: pA, personB: pB) }
        }
    }
    private var connectionHeader: some View {
        HStack(spacing: Spacing.lg) {
            personSummary(personA, isLeft: true)
            VStack(spacing: 2) { Image(systemName: "link").font(.system(size: 18, weight: .semibold)).foregroundColor(.tealLink); Text("连接").font(.cnCaption2).foregroundColor(.textTertiary) }.padding(.horizontal, Spacing.sm)
            personSummary(personB, isLeft: false)
        }.padding(Spacing.base).cardStyleSolid()
    }
    private func personSummary(_ person: Person, isLeft: Bool) -> some View {
        VStack(spacing: Spacing.sm) {
            if let primaryRole = person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 56) }
            Text(person.name).font(.cnHeadline).foregroundColor(.textPrimary).multilineTextAlignment(.center).lineLimit(1)
            HStack(spacing: Spacing.xs) { ForEach(person.roleTypes.prefix(2), id: \.self) { role in RoleTypeTag(roleType: role) } }
            if let org = person.org { Text(org).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1) }
        }.frame(maxWidth: .infinity)
    }
    private var connectionSummaryCard: some View {
        HStack(alignment: .top, spacing: Spacing.sm) { Image(systemName: "sparkles").font(.system(size: 13, weight: .medium)).foregroundColor(.tealLink.opacity(0.6)).padding(.top, 2); Text(connectionSummary).font(.cnSubhead).foregroundColor(.textSecondary).lineSpacing(3) }.padding(Spacing.base).cardStyleSolid()
    }
    private var alsoConnectedPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) { Image(systemName: "person.2.fill").font(.system(size: 12, weight: .medium)).foregroundColor(.tealLink.opacity(0.7)); Text("\(personB.name) 也连接着…").font(.cnSubhead).foregroundColor(.textSecondary) }.padding(.horizontal, Spacing.xs)
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: Spacing.sm) { ForEach(personBOtherConnections, id: \.person.persistentModelID) { item in alsoConnectedItem(item) } }.padding(.horizontal, Spacing.xs) }
        }.padding(Spacing.base).cardStyleSolid()
    }
    private func alsoConnectedItem(_ item: (person: Person, sharedCount: Int)) -> some View { Button { secondaryNavA = personB.persistentModelID; secondaryNavB = item.person.persistentModelID } label: { VStack(spacing: Spacing.xs) { if let primaryRole = item.person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 36) }; Text(item.person.name).font(.cnCaption1).foregroundColor(.textPrimary).lineLimit(1).frame(width: 56); Text("\(item.sharedCount)案").font(.cnCaption2).foregroundColor(.textTertiary) }.frame(width: 72).padding(.vertical, Spacing.sm).background(Color.surfaceLight).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard)) }.buttonStyle(.plain) }
    private var interactionTimelineCard: some View {
        let timeline = buildTimeline()
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeaderView(icon: "clock.arrow.circlepath", title: "互动时间线", count: timeline.count)
            if timeline.isEmpty { Text("暂无互动记录").font(.cnCaption1).foregroundColor(.textTertiary).padding(.vertical, Spacing.md) }
            else { ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in timelineRow(item, isLast: index == timeline.count - 1) } }
        }.padding(Spacing.base).cardStyleSolid()
    }
    private func timelineRow(_ item: TimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(spacing: 0) { Circle().fill(item.isCase ? Color.tealLink : Color.amber).frame(width: 10, height: 10); if !isLast { Rectangle().fill(Color.divider).frame(width: 1.5) } }
            VStack(alignment: .leading, spacing: Spacing.xs) { Text(item.dateLabel).font(.cnCaption2).foregroundColor(.textTertiary); HStack(spacing: Spacing.xs) { Image(systemName: item.isCase ? "briefcase.fill" : "calendar").font(.system(size: 11)).foregroundColor(item.isCase ? .tealLink : .amber); Text(item.title).font(.cnSubhead).foregroundColor(.textPrimary).lineLimit(2) }; if let subtitle = item.subtitle, !subtitle.isEmpty { Text(subtitle).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1) } }.padding(.bottom, isLast ? 0 : Spacing.md)
            Spacer()
        }
    }
    private func buildTimeline() -> [TimelineItem] {
        var items: [TimelineItem] = []
        for c in sharedCases { items.append(TimelineItem(date: c.createdAt, dateLabel: formattedDate(c.createdAt), title: c.name, subtitle: c.caseNumber, isCase: true)); for ce in c.events { items.append(TimelineItem(date: ce.date, dateLabel: formattedDate(ce.date), title: ce.title, subtitle: "\(c.name) · \(ce.eventType.rawValue)", isCase: false)) } }
        for e in sharedEvents { if let date = e.date { items.append(TimelineItem(date: date, dateLabel: formattedDate(date), title: e.title, subtitle: e.eventType.rawValue, isCase: false)) } }
        items.sort { $0.date > $1.date }; return items
    }
    private struct TimelineItem { let date: Date; let dateLabel: String; let title: String; let subtitle: String?; let isCase: Bool }
    private var sharedCasesSection: some View { VStack(alignment: .leading, spacing: Spacing.md) { sectionHeaderView(icon: "briefcase.fill", title: "共享的案件", count: sharedCases.count); VStack(spacing: Spacing.sm) { ForEach(sharedCases, id: \.persistentModelID) { c in sharedCaseRow(c) } } }.padding(Spacing.base).cardStyleSolid() }
    private func sharedCaseRow(_ c: Case) -> some View { VStack(alignment: .leading, spacing: Spacing.xs) { HStack { StatusBadge(status: c.caseStatus); Spacer() }; Text(c.name).font(.cnHeadline).foregroundColor(.textPrimary).lineLimit(2); if let caseNumber = c.caseNumber { Text(caseNumber).font(.cnMonoFootnote).foregroundColor(.textSecondary) }; HStack(spacing: Spacing.md) { if let roleA = c.casePersons.first(where: { $0.person?.persistentModelID == personA.persistentModelID })?.role { roleInCaseLabel(name: personA.name, role: roleA) }; if let roleB = c.casePersons.first(where: { $0.person?.persistentModelID == personB.persistentModelID })?.role { roleInCaseLabel(name: personB.name, role: roleB) } } }.padding(Spacing.md).background(Color.surfaceLight).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard)) }
    private func roleInCaseLabel(name: String, role: String) -> some View { HStack(spacing: 2) { Text(name).font(.cnCaption2).foregroundColor(.textPrimary); Text("·").font(.cnCaption2).foregroundColor(.textTertiary); Text(role).font(.cnCaption2).foregroundColor(.textSecondary) } }
    private var sharedEventsSection: some View { VStack(alignment: .leading, spacing: Spacing.md) { sectionHeaderView(icon: "calendar.badge.clock", title: "共同参与的事件", count: sharedEvents.count); VStack(spacing: Spacing.sm) { ForEach(sharedEvents, id: \.persistentModelID) { e in sharedEventRow(e) } } }.padding(Spacing.base).cardStyleSolid() }
    private func sharedEventRow(_ e: Event) -> some View { VStack(alignment: .leading, spacing: Spacing.xs) { HStack { Image(systemName: e.eventType.systemImage).font(.system(size: 14, weight: .medium)).foregroundColor(e.eventType.swiftUIColor); if let date = e.date { Text(date.formatted(date: .abbreviated, time: e.isAllDay ? .omitted : .shortened)).font(.cnSubhead).foregroundColor(.textSecondary) }; Spacer(); EventStatusBadge(status: e.status) }; Text(e.title).font(.cnHeadline).foregroundColor(.textPrimary).lineLimit(2); if let summary = e.summary, !summary.isEmpty { Text(summary).font(.cnCaption1).foregroundColor(.textSecondary).lineLimit(1) }; HStack(spacing: Spacing.md) { if let roleA = e.eventPersons.first(where: { $0.person?.persistentModelID == personA.persistentModelID })?.role { Label { Text("\(personA.name) · \(roleA)").font(.cnCaption2) } icon: { Image(systemName: "person.fill").font(.system(size: 9)) }.foregroundColor(.textTertiary) }; if let roleB = e.eventPersons.first(where: { $0.person?.persistentModelID == personB.persistentModelID })?.role { Label { Text("\(personB.name) · \(roleB)").font(.cnCaption2) } icon: { Image(systemName: "person.fill").font(.system(size: 9)) }.foregroundColor(.textTertiary) } } }.padding(Spacing.md).background(Color.surfaceLight).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard)) }
    private var mutualConnectionsSection: some View { VStack(alignment: .leading, spacing: Spacing.md) { sectionHeaderView(icon: "point.topleft.down.to.point.bottomright.curvepath", title: "怎么找到他 — 通过这些人", count: mutualPersons.count); VStack(spacing: 0) { ForEach(Array(mutualPersons.enumerated()), id: \.element.persistentModelID) { index, p in mutualPathRow(p); if index < mutualPersons.count - 1 { Divider().background(Color.divider).padding(.leading, Spacing.xxl + Spacing.xl) } } } }.padding(Spacing.base).cardStyleSolid() }
    private func mutualPathRow(_ p: Person) -> some View { let aCount = personA.sharedCases(with: p).count + personA.sharedEvents(with: p).count; let bCount = personB.sharedCases(with: p).count + personB.sharedEvents(with: p).count; return HStack(spacing: Spacing.md) { if let primaryRole = p.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 28) }; VStack(alignment: .leading, spacing: 1) { Text(p.name).font(.cnSubhead).foregroundColor(.textPrimary); if let org = p.org { Text(org).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1) } }; Spacer(); HStack(spacing: Spacing.xs) { Text("\(aCount)").font(.cnCaption2).foregroundColor(.textSecondary); Image(systemName: "arrow.left.and.right").font(.system(size: 8, weight: .medium)).foregroundColor(.textTertiary); Text("\(bCount)").font(.cnCaption2).foregroundColor(.textSecondary) }.padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs).background(Color.tealLink.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag)) }.padding(.vertical, Spacing.sm) }
    private var depthTwoConnectionsSection: some View { VStack(alignment: .leading, spacing: 0) { Button { withAnimation(.easeInOut(duration: 0.3)) { showDepthTwo.toggle() } } label: { HStack(spacing: Spacing.sm) { Image(systemName: "point.3.connected.trianglepath.dotted").font(.system(size: 16, weight: .semibold)).foregroundColor(.tealLink); Text("此人也连接着…").font(.cnTitle3).foregroundColor(.textPrimary); Spacer(); Text("\(personBDepthTwoConnections.count)").font(.cnSubhead).foregroundColor(.textTertiary); Image(systemName: showDepthTwo ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(.textTertiary) }.padding(Spacing.base) }.buttonStyle(.plain); if showDepthTwo { Divider().background(Color.divider).padding(.horizontal, Spacing.base); VStack(spacing: 0) { ForEach(Array(personBDepthTwoConnections.enumerated()), id: \.element.person.persistentModelID) { index, item in depthTwoConnectionRow(item); if index < personBDepthTwoConnections.count - 1 { Divider().background(Color.divider).padding(.leading, Spacing.xxl + Spacing.xl) } } }.padding(.horizontal, Spacing.base).padding(.vertical, Spacing.sm) } }.cardStyleSolid() }
    private func depthTwoConnectionRow(_ item: (person: Person, sharedCount: Int)) -> some View { Button { secondaryNavA = personB.persistentModelID; secondaryNavB = item.person.persistentModelID } label: { HStack(spacing: Spacing.md) { if let primaryRole = item.person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 32) }; VStack(alignment: .leading, spacing: 2) { Text(item.person.name).font(.cnSubhead).foregroundColor(.textPrimary); HStack(spacing: Spacing.xs) { if let primaryRole = item.person.roleTypes.first { Text(primaryRole.rawValue).font(.cnCaption2).foregroundColor(primaryRole.swiftUIColor) }; if let org = item.person.org { Text("·").foregroundColor(.textTertiary).font(.cnCaption2); Text(org).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1) } } }; Spacer(); Text("\(item.sharedCount)案").font(.cnCaption2).foregroundColor(.textSecondary).padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs).background(Color.tealLink.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag)); Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.textTertiary) }.padding(.vertical, Spacing.sm).contentShape(Rectangle()) }.buttonStyle(.plain) }
    private var emptyConnectionState: some View { VStack(spacing: Spacing.base) { Spacer().frame(height: 40); Image(systemName: "link.badge.plus").font(.system(size: 48)).foregroundColor(.tealLink.opacity(0.4)); Text("尚未建立连接").font(.cnHeadline).foregroundColor(.textPrimary); Text("\(personA.name) 和 \(personB.name) 目前没有共享的案件或事件。
一起参与的第一个案子或会议，
就是连接的开始。").font(.cnBody).foregroundColor(.textSecondary).multilineTextAlignment(.center).padding(.horizontal, Spacing.xxl) } }
    private func sectionHeaderView(icon: String, title: String, count: Int) -> some View { HStack(spacing: Spacing.sm) { Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(.tealLink); Text(title).font(.cnTitle3).foregroundColor(.textPrimary); Spacer(); Text("\(count)").font(.cnSubhead).foregroundColor(.textTertiary) } }
    private func loadConnectionData() { sharedCases = personA.sharedCases(with: personB); sharedEvents = personA.sharedEvents(with: personB); earliestDate = personA.earliestInteractionDate(with: personB); latestDate = personA.latestInteractionDate(with: personB); let descriptor = FetchDescriptor<person>(predicate: #Predicate { !$0.isArchived }); let all = (try? modelContext.fetch(descriptor)) ?? []; allPersonsCache = all; let mutualIDs = personA.mutualConnectionIDs(with: personB); mutualPersons = all.filter { mutualIDs.contains($0.persistentModelID) }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }; var otherConns: [(person: Person, sharedCount: Int)] = []; for p in all { guard p.persistentModelID != personA.persistentModelID, p.persistentModelID != personB.persistentModelID else { continue }; let count = personB.sharedCases(with: p).count; if count > 0 { otherConns.append((person: p, sharedCount: count)) } }; otherConns.sort { $0.sharedCount > $1.sharedCount }; personBOtherConnections = Array(otherConns.prefix(5)); personBDepthTwoConnections = otherConns.sorted { $0.person.name.localizedCompare($1.person.name) == .orderedAscending }; connectionSummary = buildConnectionSummary() }
    private func buildConnectionSummary() -> String { let totalConnections = sharedCases.count + sharedEvents.count; guard totalConnections > 0 else { return "" }; var parts: [String] = []; let name = personB.name; if let org = personB.org { parts.append("\(name)，\(org)") } else { parts.append(name) }; let freq = personA.interactionFrequency(with: personB); if freq > totalConnections { parts.append("共事于\(totalConnections)个案件/事件，累计互动\(freq)次") } else { parts.append("共事于\(totalConnections)个案件/事件") }; if let latest = latestDate { let formatter = RelativeDateTimeFormatter(); formatter.locale = Locale(identifier: "zh_Hans_CN"); formatter.unitsStyle = .abbreviated; parts.append("最近一次\(formatter.localizedString(for: latest, relativeTo: Date()))") }; if !mutualPersons.isEmpty { let roleGroups = Dictionary(grouping: mutualPersons) { ($0.roleTypes.first ?? .other).rawValue }; let roleSummary = roleGroups.sorted { $0.value.count > $1.value.count }.prefix(3).map { "\($0.value.count)位\($0.key)" }.joined(separator: "、"); parts.append("通过他连接着\(roleSummary)") }; return parts.joined(separator: "。") }
    private func formattedDate(_ date: Date) -> String { let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0; if days == 0 { return "今天" } else if days == 1 { return "昨天" } else if days <= 7 { return "\(days)天前" } else if Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date()) { formatter.dateFormat = "M月d日" } else { formatter.dateFormat = "yyyy年M月d日" }; return formatter.string(from: date) }
}
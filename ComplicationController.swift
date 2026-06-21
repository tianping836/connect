import ClockKit
import SwiftUI
import SwiftData
final class ComplicationController: NSObject, CLKComplicationDataSource {
    static let shared = ComplicationController()
    private let dataManager = WatchDataManager.shared; private var nextHearingDate: Date?
    func complicationDescriptors() async -> [CLKComplicationDescriptor] { [CLKComplicationDescriptor(identifier: "com.islandlink.nextHearing", displayName: "下个开庭", supportedFamilies: [.graphicCircular, .graphicCorner])] }
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? { refreshNextHearing(); return makeEntry(for: complication, date: Date()) }
    func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry]? { refreshNextHearing(); guard let hearingDate = nextHearingDate else { return [makeEntry(for: complication, date: Date())] }; var entries: [CLKComplicationTimelineEntry] = []; var cursor = max(date, Date()); for _ in 0..<min(limit, 100)="" {="" guard="" cursor="" <="" hearingdate="" else="" break="" };="" entries.append(makeentry(for:="" complication,="" date:="" cursor));="" let="" next="Calendar.current.date(byAdding:" .hour,="" value:="" 6,="" to:="" cursor)="" return="" entries.isempty="" ?="" [makeentry(for:="" date())]="" :="" entries="" }="" private="" func="" makeentry(for="" complication:="" clkcomplication,="" date)="" -=""> CLKComplicationTimelineEntry { let template: CLKComplicationTemplate; switch complication.family { case .graphicCircular: template = makeGraphicCircularTemplate(); case .graphicCorner: template = makeGraphicCornerTemplate(); default: template = makeGraphicCircularTemplate() }; return CLKComplicationTimelineEntry(date: date, complicationTemplate: template) }
    private func makeGraphicCircularTemplate() -> CLKComplicationTemplateGraphicCircularView { CLKComplicationTemplateGraphicCircularView(GraphicCircularView(nextHearingDate: nextHearingDate)) }
    private func makeGraphicCornerTemplate() -> CLKComplicationTemplateGraphicCornerCircularView { CLKComplicationTemplateGraphicCornerCircularView(GraphicCornerView(nextHearingDate: nextHearingDate)) }
    private func refreshNextHearing() { nextHearingDate = dataManager.nextCourtHearing() }
    func reloadActiveComplications() { let server = CLKComplicationServer.sharedInstance(); server.activeComplications?.forEach { server.reloadTimeline(for: $0) } }
}
private struct GraphicCircularView: View {
    let nextHearingDate: Date?; private let tealLink = Color(red: 0/255, green: 137/255, blue: 123/255); private let coralWarm = Color(red: 224/255, green: 123/255, blue: 90/255)
    var body: some View { ZStack { Circle().stroke(.white.opacity(0.15), lineWidth: 4); Circle().trim(from: 0, to: progress).stroke(nextHearingDate != nil ? coralWarm : tealLink, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90)); VStack(spacing: -2) { Text(daysText).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.white); Text(daysLabel).font(.system(size: 8, weight: .medium)).foregroundColor(.white.opacity(0.6)) } }.padding(4) }
    private var daysText: String { guard let date = nextHearingDate else { return "--" }; let days = daysUntil(date); return "\(days)" }
    private var daysLabel: String { nextHearingDate == nil ? "无开庭" : "天" }
    private var progress: CGFloat { guard let date = nextHearingDate else { return 0 }; let totalDays = 30.0; let remaining = Double(daysUntil(date)); return CGFloat(min(max(1 - remaining / totalDays, 0.05), 1.0)) }
    private func daysUntil(_ date: Date) -> Int { let today = Calendar.current.startOfDay(for: Date()); let target = Calendar.current.startOfDay(for: date); return max(Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0, 0) }
}
private struct GraphicCornerView: View {
    let nextHearingDate: Date?; private let coralWarm = Color(red: 224/255, green: 123/255, blue: 90/255)
    var body: some View { ZStack { Circle().fill(coralWarm.opacity(0.25)); VStack(spacing: -2) { Text(daysText).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(coralWarm); Text(daysLabel).font(.system(size: 8, weight: .medium)).foregroundColor(coralWarm.opacity(0.8)) } } }
    private var daysText: String { guard let date = nextHearingDate else { return "--" }; let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0; return "\(max(days, 0))" }
    private var daysLabel: String { nextHearingDate == nil ? "无" : "开庭" }
}
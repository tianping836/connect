import SwiftUI
import SwiftData

/// 设置页 — Apple 风格 InsetGroupedListStyle
struct SettingsView: View {
    @AppStorage("caseModuleEnabled") private var caseModuleEnabled: Bool = true
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @EnvironmentObject private var subManager: SubscriptionManager
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showResetConfirm = false
    @State private var showRedeemSheet = false
    @State private var showCodeGenerator = false
    @State private var showAuthorPasscodeAlert = false
    @State private var authorPasscodeInput = ""
    @AppStorage("author_passcode") private var authorPasscode: String = "lvwujie2018"
    @Query(sort: \RedeemCode.generatedAt, order: .reverse) private var allCodes: [RedeemCode]

    var body: some View {
        NavigationStack {
            List {
                Section { HStack(spacing: Spacing.md) {
                    Image(systemName: "folder.fill").font(.system(size: 20)).foregroundColor(.tealLink).frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) { Text("案件管理").font(.cnBody).foregroundColor(.textPrimary); Text("关闭后，案件板块将从主界面隐藏。你的事件和日历不受影响。").font(.cnCaption1).foregroundColor(.textTertiary) }
                    Spacer(); Toggle("", isOn: $caseModuleEnabled).labelsHidden().tint(.tealLink)
                }.padding(.vertical, Spacing.xs) } header: { Text("功能模块") }
                Section { settingsRow(title: "应用锁", systemImage: "lock.fill", iconColor: .coralWarm, trailing: { Toggle("", isOn: $appLockEnabled).labelsHidden().tint(.tealLink) }) } header: { Text("安全") }
                Section { VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) { Image(systemName: "text.bubble.fill").font(.system(size: 20)).foregroundColor(.coralWarm).frame(width: 28); VStack(alignment: .leading, spacing: 2) { Text("App 语调").font(.cnBody).foregroundColor(.textPrimary); Text("选择更符合你风格的文案表达方式").font(.cnCaption1).foregroundColor(.textTertiary) } }; AppTonePicker()
                }.padding(.vertical, Spacing.xs) } header: { Text("外观与交互") }
                Section { OnboardingProgressView().padding(.vertical, Spacing.xs) } header: { Text("功能引导") }
                Section { settingsRow(title: "iCloud 同步", systemImage: "icloud.fill", iconColor: .statusInfo, trailing: { Toggle("", isOn: $iCloudSyncEnabled).labelsHidden().tint(.tealLink) })
                    if iCloudSyncEnabled { Text("开启后，你的案件和人脉数据会自动在你所有设备间同步。").font(.cnCaption1).foregroundColor(.textTertiary) }
                } header: { Text("同步") }
                Section { VStack(spacing: Spacing.sm) {
                    HStack { ZStack { Circle().fill(subManager.isPro ? Color.tealLink.opacity(0.15) : Color.textTertiary.opacity(0.1)).frame(width: 40, height: 40); Image(systemName: subManager.isPro ? "crown.fill" : "crown").font(.system(size: 20)).foregroundColor(subManager.isPro ? .tealLink : .textTertiary) }
                        VStack(alignment: .leading, spacing: 2) { Text(subManager.isPro ? "Pro 会员" : "免费版").font(.cnHeadline).foregroundColor(.textPrimary); Text(proSubtitle).font(.cnCaption1).foregroundColor(.textTertiary) }
                        Spacer(); if !subManager.isPro { Button { subManager.showUpgradeSheet = true } label: { Text("升级").font(.cnCaption2.weight(.bold)).foregroundColor(.white).padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm).background(RoundedRectangle(cornerRadius: CornerRadius.tag).fill(Color.tealLink)) } }
                    }
                    VStack(spacing: Spacing.sm) { usageRow(label: "人脉联系人", icon: "person.2", count: subManager.personCount, limit: SubscriptionManager.freePersonLimit, isPro: subManager.isPro); usageRow(label: "案件与事件", icon: "folder", count: subManager.caseEventCount, limit: SubscriptionManager.freeCaseEventLimit, isPro: subManager.isPro) }
                    if !subManager.isPro || subManager.proSource == .invitation { Divider(); Button { showRedeemSheet = true } label: { HStack { Image(systemName: "gift").font(.system(size: 14)).foregroundColor(.tealLink); Text("兑换邀请码").font(.cnCallout).foregroundColor(.textPrimary); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.textTertiary) } } }
                }.padding(.vertical, Spacing.sm) } header: { Text("会员") }
                Section { Button { showExportSheet = true } label: { settingsRowContent(title: "导出全部数据", systemImage: "arrow.up.doc.fill", iconColor: .tealLink) }; Button { showImportSheet = true } label: { settingsRowContent(title: "从 JSON 导入", systemImage: "arrow.down.doc.fill", iconColor: .tealLink) }; Button { showImportSheet = true } label: { settingsRowContent(title: "从 CSV 导入案件", systemImage: "tray.and.arrow.down.fill", iconColor: .tealLink) } } header: { Text("数据管理") }
                Section { Button(role: .destructive) { showResetConfirm = true } label: { HStack { Image(systemName: "trash.fill").font(.system(size: 20)).foregroundColor(.statusError).frame(width: 28); Text("重置所有数据").foregroundColor(.statusError) } } } header: { Text("危险操作") }
                Section { HStack { Spacer(); Text("连接 v1.0 · 构建于 SwiftUI").font(.cnCaption1).foregroundColor(.textTertiary).onLongPressGesture(minimumDuration: 3.0) { showAuthorPasscodeAlert = true }; Spacer() }.listRowBackground(Color.clear) }
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(Color.surfaceLight).navigationTitle("设置")
            .alert("重置所有数据", isPresented: $showResetConfirm) { Button("取消", role: .cancel) {}; Button("重置", role: .destructive) {} } message: { Text("确定要删除所有数据吗？此操作不可撤销。") }
            .alert(authorPasscode.isEmpty ? "设置作者密码" : "作者验证", isPresented: $showAuthorPasscodeAlert) { SecureField(authorPasscode.isEmpty ? "设定一个暗号" : "请输入暗号", text: $authorPasscodeInput); Button("确定") { verifyAndOpenGenerator() }; Button("取消", role: .cancel) { authorPasscodeInput = "" } } message: { if authorPasscode.isEmpty { Text("请设定一个只有你知道的暗号，之后长按将需要验证。") } }
            .sheet(isPresented: $subManager.showUpgradeSheet) { UpgradeSheet().environmentObject(subManager) }
            .sheet(isPresented: $showRedeemSheet) { RedeemSheet().environmentObject(subManager) }
            .sheet(isPresented: $showCodeGenerator) { CodeGeneratorSheet() }
        }
    }
    private func verifyAndOpenGenerator() { defer { authorPasscodeInput = "" }; if authorPasscode.isEmpty { authorPasscode = authorPasscodeInput; showCodeGenerator = true; return }; if authorPasscodeInput == authorPasscode { showCodeGenerator = true } }
    private var proSubtitle: String { if subManager.proSource == .invitation { let days = subManager.invitationDaysRemaining; return "邀请兑换 · 还剩 \(days) 天" }; return subManager.isPro ? "已解锁全部功能，感谢支持" : "¥99/年 解锁无限使用" }
    private func usageRow(label: String, icon: String, count: Int, limit: Int, isPro: Bool) -> some View {
        VStack(spacing: 4) {
            HStack { Image(systemName: icon).font(.system(size: 12)).foregroundColor(.textTertiary); Text(label).font(.cnCaption1).foregroundColor(.textSecondary); Spacer(); Text(isPro ? "\(count)/无限" : "\(count)/\(limit)").font(.cnCaption1).foregroundColor(.textTertiary) }
            GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(Color.textTertiary.opacity(0.12)).frame(height: 4); if !isPro { RoundedRectangle(cornerRadius: 2).fill(barColor(count: count, limit: limit)).frame(width: barWidth(count: count, limit: limit, totalWidth: geo.size.width), height: 4) } else { RoundedRectangle(cornerRadius: 2).fill(Color.tealLink.opacity(0.6)).frame(width: geo.size.width, height: 4) } } }.frame(height: 4)
        }
    }
    private func barWidth(count: Int, limit: Int, totalWidth: CGFloat) -> CGFloat { let ratio = min(CGFloat(count) / CGFloat(limit), 1.0); return max(ratio * totalWidth, 4) }
    private func barColor(count: Int, limit: Int) -> Color { let ratio = CGFloat(count) / CGFloat(limit); if ratio < 0.7 { return .tealLink }; if ratio < 0.9 { return .statusWarning }; return .coralWarm }
    private func settingsRow<trailing: view="">(title: String, systemImage: String, iconColor: Color, @ViewBuilder trailing: () -> Trailing) -> some View { HStack(spacing: Spacing.md) { Image(systemName: systemImage).font(.system(size: 20)).foregroundColor(iconColor).frame(width: 28); Text(title).font(.cnBody).foregroundColor(.textPrimary); Spacer(); trailing() }.padding(.vertical, Spacing.xs) }
    private func settingsRowContent(title: String, systemImage: String, iconColor: Color) -> some View { HStack(spacing: Spacing.md) { Image(systemName: systemImage).font(.system(size: 20)).foregroundColor(iconColor).frame(width: 28); Text(title).font(.cnBody).foregroundColor(.textPrimary); Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.textTertiary) }.padding(.vertical, Spacing.xs) }
}
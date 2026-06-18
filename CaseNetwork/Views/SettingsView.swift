import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// 设置页——应用锁 + 数据导出/导入/清除 + CloudKit 同步状态
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var appLockEnabled: Bool
    @State private var lockDelay: AppLockDelay
    @State private var cloudSyncEnabled: Bool
    @State private var showClearConfirmation = false
    @State private var showImporter = false
    @State private var showCSVImporter = false
    @State private var importMode: ImportMode = .json
    @State private var showContactsCSVImporter = false
    @State private var lastActionResult: ActionResult?

    let biometryName = BiometricAuthService.shared.biometryName
    let biometryAvailable = BiometricAuthService.shared.isBiometryAvailable

    init() {
        _appLockEnabled = State(initialValue: BiometricAuthService.shared.isAppLockEnabled)
        _lockDelay = State(initialValue: BiometricAuthService.shared.lockDelay)
        _cloudSyncEnabled = State(initialValue: UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled"))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 安全
                securitySection

                // MARK: 同步
                syncSection

                // MARK: 数据
                dataSection
            }
            .formStyle(.grouped)
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .fileImporter(
                isPresented: $showCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .delimitedText],
                allowsMultipleSelection: false
            ) { result in
                handleCSVImport(result)
            }
            .fileImporter(
                isPresented: $showContactsCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .delimitedText],
                allowsMultipleSelection: false
            ) { result in
                handleContactsCSVImport(result)
            }
            .alert("清除全部数据", isPresented: $showClearConfirmation) {
                clearConfirmationButtons
            } message: {
                Text("此操作不可撤销。所有联系人、案件、机构、事件将被永久删除。\n建议先导出备份。")
            }
            .overlay(alignment: .bottom) {
                // 操作结果提示
                if let result = lastActionResult {
                    resultBanner(result)
                }
            }
        }
    }

    // MARK: - 安全

    @ViewBuilder
    private var securitySection: some View {
        Section {
            Toggle("应用锁", isOn: $appLockEnabled)
                .onChange(of: appLockEnabled) { _, newValue in
                    BiometricAuthService.shared.isAppLockEnabled = newValue
                }

            if appLockEnabled, biometryAvailable {
                Picker("锁定时机", selection: $lockDelay) {
                    ForEach(AppLockDelay.allCases, id: \.rawValue) { delay in
                        Text(delay.displayName).tag(delay)
                    }
                }
                .onChange(of: lockDelay) { _, newValue in
                    BiometricAuthService.shared.lockDelay = newValue
                }
            }

            if appLockEnabled, !biometryAvailable {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("当前设备不支持生物识别，将使用设备密码验证")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("安全", systemImage: "lock.shield")
        } footer: {
            if appLockEnabled {
                Text("App 进入后台时自动锁定，需要 \(biometryName) 或设备密码解锁。")
            }
        }
    }

    // MARK: - 同步

    @ViewBuilder
    private var syncSection: some View {
        Section {
            Toggle("iCloud 同步", isOn: $cloudSyncEnabled)
                .onChange(of: cloudSyncEnabled) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "cloudkit_sync_enabled")
                    if newValue {
                        lastActionResult = .init(
                            message: "iCloud 同步已启用。需要重启 App 生效。",
                            isError: false
                        )
                    } else {
                        lastActionResult = .init(
                            message: "iCloud 同步已关闭。本地数据不受影响。",
                            isError: false
                        )
                    }
                }

            HStack {
                Image(systemName: cloudSyncEnabled ? "icloud.fill" : "icloud.slash")
                    .foregroundStyle(cloudSyncEnabled ? .blue : .secondary)
                Text(cloudSyncEnabled ? "数据将自动同步到 iCloud" : "数据仅存储在本机")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("同步", systemImage: "icloud")
        } footer: {
            Text("启用后，数据将在登录同一 iCloud 账户的设备间自动同步（需在 Xcode 项目中配置 iCloud / CloudKit 能力）。")
        }
    }

    // MARK: - 数据

    @ViewBuilder
    private var dataSection: some View {
        Section {
            // JSON 全量导出
            Button {
                performExportJSON()
            } label: {
                Label("导出全部数据 (JSON)", systemImage: "doc.text")
            }

            // CSV 导出
            Menu {
                Button("联系人 (.csv)") { performExportCSV(type: .contacts) }
                Button("案件 (.csv)") { performExportCSV(type: .cases) }
                Button("机构 (.csv)") { performExportCSV(type: .organizations) }
                Button("大事记 (.csv)") { performExportCSV(type: .events) }
            } label: {
                Label("导出为 CSV...", systemImage: "tablecells")
            }

            // JSON 导入
            Button {
                importMode = .json
                showImporter = true
            } label: {
                Label("从 JSON 导入...", systemImage: "square.and.arrow.down")
            }

            // CSV 导入案件
            Button {
                importMode = .csv
                showCSVImporter = true
            } label: {
                Label("从 CSV 导入案件...", systemImage: "tablecells.badge.arrow.down")
            }

            // CSV 导入人脉
            Button {
                showContactsCSVImporter = true
            } label: {
                Label("从 CSV 导入人脉...", systemImage: "person.text.rectangle")
            }

            Divider()

            // 清除全部数据
            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("清除全部数据", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } header: {
            Label("数据管理", systemImage: "externaldrive")
        } footer: {
            Text("导出为 JSON 格式，含全部关联关系，可用于备份或迁移。CSV 格式适合 Excel 查看。")
        }
    }

    // MARK: - 清除确认

    @ViewBuilder
    private var clearConfirmationButtons: some View {
        Button("取消", role: .cancel) {}
        Button("导出并清除") {
            // 先导出备份，再清除
            do {
                let url = try DataExportService.shared.exportAllJSON(modelContext: modelContext)
                let count = try DataExportService.shared.clearAllData(modelContext: modelContext)
                lastActionResult = .init(
                    message: "已清除 \(count) 条记录。备份已保存。",
                    isError: false,
                    fileURL: url
                )
            } catch {
                lastActionResult = .init(message: "操作失败: \(error.localizedDescription)", isError: true)
            }
        }
        Button("直接清除", role: .destructive) {
            do {
                let count = try DataExportService.shared.clearAllData(modelContext: modelContext)
                lastActionResult = .init(message: "已清除 \(count) 条记录", isError: false)
            } catch {
                lastActionResult = .init(message: "操作失败: \(error.localizedDescription)", isError: true)
            }
        }
    }

    // MARK: - 操作

    private func performExportJSON() {
        do {
            let url = try DataExportService.shared.exportAllJSON(modelContext: modelContext)
            lastActionResult = .init(message: "JSON 导出完成", isError: false, fileURL: url)
            showInFinder(url)
        } catch {
            lastActionResult = .init(message: "导出失败: \(error.localizedDescription)", isError: true)
        }
    }

    private func performExportCSV(type: CSVExportType) {
        do {
            let url: URL
            switch type {
            case .contacts:
                url = try DataExportService.shared.exportContactsCSV(modelContext: modelContext)
            case .cases:
                url = try DataExportService.shared.exportCasesCSV(modelContext: modelContext)
            case .organizations:
                url = try DataExportService.shared.exportOrganizationsCSV(modelContext: modelContext)
            case .events:
                url = try DataExportService.shared.exportEventsCSV(modelContext: modelContext)
            }
            lastActionResult = .init(message: "\(type.displayName) CSV 导出完成", isError: false, fileURL: url)
            showInFinder(url)
        } catch {
            lastActionResult = .init(message: "导出失败: \(error.localizedDescription)", isError: true)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try DataExportService.shared.importFromJSON(url, modelContext: modelContext)
                lastActionResult = .init(message: "已导入 \(count) 条记录", isError: false)
            } catch {
                lastActionResult = .init(message: "导入失败: \(error.localizedDescription)", isError: true)
            }
        case .failure(let error):
            lastActionResult = .init(message: "文件选择失败: \(error.localizedDescription)", isError: true)
        }
    }

    private func handleCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try DataExportService.shared.importCasesFromCSV(url, modelContext: modelContext)
                lastActionResult = .init(message: "已导入 \(count) 个案件", isError: false)
            } catch {
                lastActionResult = .init(message: "导入失败: \(error.localizedDescription)", isError: true)
            }
        case .failure(let error):
            lastActionResult = .init(message: "文件选择失败: \(error.localizedDescription)", isError: true)
        }
    }

    private func handleContactsCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try DataExportService.shared.importContactsFromCSV(url, modelContext: modelContext)
                lastActionResult = .init(message: "已导入 \(count) 位人脉", isError: false)
            } catch {
                lastActionResult = .init(message: "导入失败: \(error.localizedDescription)", isError: true)
            }
        case .failure(let error):
            lastActionResult = .init(message: "文件选择失败: \(error.localizedDescription)", isError: true)
        }
    }

    // MARK: - 跨平台工具

    /// 在 Finder / 文件中显示
    private func showInFinder(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #elseif os(iOS)
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(controller, animated: true)
        }
        #endif
    }

    // MARK: - 结果提示

    @ViewBuilder
    private func resultBanner(_ result: ActionResult) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: result.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(result.isError ? .red : .green)
                Text(result.message)
                    .font(.callout)
                Spacer()
                if let fileURL = result.fileURL {
                    Button("查看") {
                        showInFinder(fileURL)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(6))
                withAnimation(.easeInOut(duration: 0.3)) { lastActionResult = nil }
            }
        }
    }
}

// MARK: - 辅助类型

private enum ImportMode {
    case json, csv
}

private enum CSVExportType {
    case contacts, cases, organizations, events

    var displayName: String {
        switch self {
        case .contacts: return "联系人"
        case .cases: return "案件"
        case .organizations: return "机构"
        case .events: return "大事记"
        }
    }
}

private struct ActionResult {
    let message: String
    let isError: Bool
    var fileURL: URL?
}

#Preview {
    SettingsView()
        .modelContainer(for: [Contact.self, CaseRecord.self, Organization.self, KeyEvent.self])
}

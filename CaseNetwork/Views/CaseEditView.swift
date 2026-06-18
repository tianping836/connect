import SwiftUI
import SwiftData

/// 新建 / 编辑案件表单
struct CaseEditView: View {
    var caseRecord: CaseRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Organization.name) private var organizations: [Organization]
    @Query(sort: \Contact.name) private var contacts: [Contact]

    @State private var caseName = ""
    @State private var caseType: CaseType = .civil
    @State private var courtCaseNumber = ""
    @State private var internalCaseNumber = ""
    @State private var claimAmount: Double?
    @State private var hasAmount = false
    @State private var claimSummary = ""
    @State private var caseResult = ""
    @State private var caseStage: CaseStage = .consulting
    @State private var filingDate: Date?
    @State private var hasFilingDate = false
    @State private var closingDate: Date?
    @State private var hasClosingDate = false
    @State private var selectedOrg: Organization?
    @State private var selectedLawyer: Contact?
    @State private var notes = ""

    private var isEditing: Bool { caseRecord != nil }
    private var title: String { isEditing ? "编辑" : "新建案件" }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("案件名称 *", text: $caseName)
                    Picker("类型", selection: $caseType) {
                        ForEach(CaseType.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    TextField("法院案号", text: $courtCaseNumber)
                    TextField("委托号", text: $internalCaseNumber)
                }

                Section("状态与阶段") {
                    Picker("阶段", selection: $caseStage) {
                        ForEach(CaseStage.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                }

                Section("标的与诉请") {
                    Toggle("有标的额", isOn: $hasAmount)
                    if hasAmount {
                        TextField("标的额（元）", value: $claimAmount, format: .number)
                    }
                    TextField("诉请摘要", text: $claimSummary, axis: .vertical)
                        .lineLimit(3)
                }

                Section("日期") {
                    Toggle("立案日期", isOn: $hasFilingDate)
                    if hasFilingDate {
                        DatePicker("立案", selection: Binding(
                            get: { filingDate ?? Date() }, set: { filingDate = $0 }),
                                   displayedComponents: .date)
                    }
                    Toggle("结案日期", isOn: $hasClosingDate)
                    if hasClosingDate {
                        DatePicker("结案", selection: Binding(
                            get: { closingDate ?? Date() }, set: { closingDate = $0 }),
                                   displayedComponents: .date)
                    }
                }

                Section("机构与负责律师") {
                    Picker("机构", selection: $selectedOrg) {
                        Text("无").tag(nil as Organization?)
                        ForEach(organizations) { org in Text(org.name).tag(org as Organization?) }
                    }
                    Picker("负责律师", selection: $selectedLawyer) {
                        Text("无").tag(nil as Contact?)
                        ForEach(contacts.filter { $0.roleTags.contains(.lawyer) }) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }
                }

                if isEditing {
                    Section("结果") {
                        TextField("案件结果", text: $caseResult, axis: .vertical)
                            .lineLimit(3)
                    }
                }

                Section("备注") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveCase() }.disabled(caseName.isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func saveCase() {
        if let existing = caseRecord {
            existing.caseName = caseName
            existing.caseType = caseType
            existing.courtCaseNumber = courtCaseNumber.isEmpty ? nil : courtCaseNumber
            existing.internalCaseNumber = internalCaseNumber.isEmpty ? nil : internalCaseNumber
            existing.claimAmount = hasAmount ? claimAmount : nil
            existing.claimSummary = claimSummary.isEmpty ? nil : claimSummary
            existing.caseResult = caseResult.isEmpty ? nil : caseResult
            existing.caseStage = caseStage
            existing.filingDate = hasFilingDate ? filingDate : nil
            existing.closingDate = hasClosingDate ? closingDate : nil
            existing.acceptedOrganization = selectedOrg
            existing.responsibleLawyer = selectedLawyer
            existing.notes = notes.isEmpty ? nil : notes
            existing.updatedAt = Date()
        } else {
            let newCase = CaseRecord(
                caseName: caseName,
                caseType: caseType,
                courtCaseNumber: courtCaseNumber.isEmpty ? nil : courtCaseNumber,
                internalCaseNumber: internalCaseNumber.isEmpty ? nil : internalCaseNumber,
                claimAmount: hasAmount ? claimAmount : nil,
                claimSummary: claimSummary.isEmpty ? nil : claimSummary,
                caseStage: caseStage,
                filingDate: hasFilingDate ? filingDate : nil,
                closingDate: hasClosingDate ? closingDate : nil,
                acceptedOrganization: selectedOrg,
                responsibleLawyer: selectedLawyer,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(newCase)
        }
        try? modelContext.save()
        dismiss()
    }

    private func loadExisting() {
        guard let existing = caseRecord else { return }
        caseName = existing.caseName
        caseType = existing.caseType
        courtCaseNumber = existing.courtCaseNumber ?? ""
        internalCaseNumber = existing.internalCaseNumber ?? ""
        if let amt = existing.claimAmount { hasAmount = true; claimAmount = amt }
        claimSummary = existing.claimSummary ?? ""
        caseResult = existing.caseResult ?? ""
        caseStage = existing.caseStage
        if let fd = existing.filingDate { hasFilingDate = true; filingDate = fd }
        if let cd = existing.closingDate { hasClosingDate = true; closingDate = cd }
        selectedOrg = existing.acceptedOrganization
        selectedLawyer = existing.responsibleLawyer
        notes = existing.notes ?? ""
    }
}

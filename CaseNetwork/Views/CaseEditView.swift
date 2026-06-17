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
    private var title: String { isEditing ? "Edit" : "New Case" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Case name *", text: $caseName)
                    Picker("Type", selection: $caseType) {
                        ForEach(CaseType.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    TextField("Court case No.", text: $courtCaseNumber)
                    TextField("Reference No.", text: $internalCaseNumber)
                }

                Section("Status & Stage") {
                    Picker("Stage", selection: $caseStage) {
                        ForEach(CaseStage.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                }

                Section("Amount & Claim") {
                    Toggle("Has claim amount", isOn: $hasAmount)
                    if hasAmount {
                        TextField("Amount (CNY)", value: $claimAmount, format: .number)
                    }
                    TextField("Claim summary", text: $claimSummary, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Dates") {
                    Toggle("Filing date", isOn: $hasFilingDate)
                    if hasFilingDate {
                        DatePicker("Filing", selection: Binding(
                            get: { filingDate ?? Date() }, set: { filingDate = $0 }),
                                   displayedComponents: .date)
                    }
                    Toggle("Closing date", isOn: $hasClosingDate)
                    if hasClosingDate {
                        DatePicker("Closing", selection: Binding(
                            get: { closingDate ?? Date() }, set: { closingDate = $0 }),
                                   displayedComponents: .date)
                    }
                }

                Section("Organization & Responsible") {
                    Picker("Organization", selection: $selectedOrg) {
                        Text("None").tag(nil as Organization?)
                        ForEach(organizations) { org in Text(org.name).tag(org as Organization?) }
                    }
                    Picker("Responsible Lawyer", selection: $selectedLawyer) {
                        Text("None").tag(nil as Contact?)
                        ForEach(contacts.filter { $0.roleTags.contains(.lawyer) }) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }
                }

                if isEditing {
                    Section("Result") {
                        TextField("Case result", text: $caseResult, axis: .vertical)
                            .lineLimit(3)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCase() }.disabled(caseName.isEmpty)
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

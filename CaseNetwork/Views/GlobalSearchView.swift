import SwiftUI
import SwiftData

/// 全局搜索——同时搜索联系人和案件，分组展示
struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Query(sort: \CaseRecord.caseName) private var allCases: [CaseRecord]

    @State private var searchText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    recentSection
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: .automatic, prompt: "Search names, cases, courts, tags...")
            .focused($isFocused)
            .onReceive(NotificationCenter.default.publisher(for: .newItemRequested)) { notif in
                if let tab = notif.object as? AppTab, tab == .search {
                    isFocused = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSearchRequested)) { _ in
                isFocused = true
            }
            .onAppear { isFocused = true }
        }
    }

    // MARK: - 搜索结果

    private var searchResults: some View {
        let query = searchText.lowercased()

        let matchedContacts = allContacts.filter {
            $0.name.lowercased().contains(query)
            || ($0.phone ?? "").contains(query)
            || ($0.organization?.name ?? "").lowercased().contains(query)
            || $0.skillTags.contains { $0.lowercased().contains(query) }
        }

        let matchedCases = allCases.filter {
            $0.caseName.lowercased().contains(query)
            || ($0.courtCaseNumber ?? "").lowercased().contains(query)
            || ($0.internalCaseNumber ?? "").lowercased().contains(query)
            || ($0.acceptedOrganization?.name ?? "").lowercased().contains(query)
            || ($0.caseResult ?? "").lowercased().contains(query)
        }

        let isEmpty = matchedContacts.isEmpty && matchedCases.isEmpty

        return List {
            if isEmpty {
                ContentUnavailableView.search(text: searchText)
            }

            if !matchedContacts.isEmpty {
                Section("Contacts (\(matchedContacts.count))") {
                    ForEach(matchedContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }

            if !matchedCases.isEmpty {
                Section("Cases (\(matchedCases.count))") {
                    ForEach(matchedCases) { caseRecord in
                        NavigationLink {
                            CaseDetailView(caseRecord: caseRecord)
                        } label: {
                            CaseRowView(caseRecord: caseRecord)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - 快捷入口（未搜索时）

    private var recentSection: some View {
        List {
            // 重要联系人
            let important = allContacts
                .filter { $0.importance >= 4 && !$0.isArchived }
                .prefix(5)
            if !important.isEmpty {
                Section("Key Contacts") {
                    ForEach(Array(important)) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }

            // 活跃案件
            let activeCases = allCases
                .filter { $0.caseStage.isActive }
                .sorted { ($0.filingDate ?? .distantPast) > ($1.filingDate ?? .distantPast) }
                .prefix(5)
            if !activeCases.isEmpty {
                Section("Active Cases") {
                    ForEach(Array(activeCases)) { caseRecord in
                        NavigationLink {
                            CaseDetailView(caseRecord: caseRecord)
                        } label: {
                            CaseRowView(caseRecord: caseRecord)
                        }
                    }
                }
            }

            // 快捷操作
            Section("Quick Actions") {
                NavigationLink {
                    ContactListView()
                } label: {
                    Label("All contacts (\(allContacts.count))", systemImage: "person.3")
                }
                NavigationLink {
                    CaseListView()
                } label: {
                    Label("All cases (\(allCases.count))", systemImage: "doc.text")
                }
            }
        }
        .listStyle(.inset)
    }
}

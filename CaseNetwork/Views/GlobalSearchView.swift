import SwiftUI
import SwiftData

/// 全局搜索——同时搜索联系人和案件，分组展示 + 搜索历史
struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Query(sort: \CaseRecord.caseName) private var allCases: [CaseRecord]

    @State private var searchText = ""
    @State private var history = SearchHistory.shared.items
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    defaultView
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: .automatic, prompt: "Search names, cases, courts, tags...")
            .focused($isFocused)
            .onSubmit(of: .search) {
                // 提交搜索时记录历史
                if !searchText.isEmpty {
                    SearchHistory.shared.add(searchText)
                    history = SearchHistory.shared.items
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .newItemRequested)) { notif in
                if let tab = notif.object as? AppTab, tab == .search {
                    isFocused = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSearchRequested)) { _ in
                isFocused = true
            }
            .onAppear {
                isFocused = true
                history = SearchHistory.shared.items
            }
        }
    }

    // MARK: - 搜索结果

    private var searchResults: some View {
        let query = searchText.lowercased()

        let matchedContacts = allContacts.filter {
            $0.matchesSearchQuery(query)
        }

        let matchedCases = allCases.filter {
            $0.matchesSearchQuery(query)
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

    // MARK: - 默认视图（搜索历史 + 快捷入口）

    private var defaultView: some View {
        List {
            // 搜索历史
            if !history.isEmpty {
                Section {
                    ForEach(history, id: \.self) { item in
                        Button {
                            searchText = item
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(item)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    withAnimation {
                                        SearchHistory.shared.remove(item)
                                        history = SearchHistory.shared.items
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent searches")
                        Spacer()
                        Button("Clear") {
                            withAnimation {
                                SearchHistory.shared.clear()
                                history = []
                            }
                        }
                        .font(.caption)
                    }
                }
            }

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

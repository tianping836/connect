import SwiftUI
import SwiftData

/// 案件列表页——Pipeline 看板 / 阶段筛选 / 搜索
struct CaseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaseRecord.filingDate, order: .reverse) private var cases: [CaseRecord]

    @State private var viewModel = CaseListViewModel()
    @State private var showAddCase = false

    var body: some View {
        NavigationStack {
            Group {
                if cases.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Cases")
            .searchable(text: $viewModel.searchText, prompt: "Search cases, case numbers, courts...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddCase = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Toggle("Active only", isOn: $viewModel.showOnlyActive)
                }
            }
            .sheet(isPresented: $showAddCase) {
                CaseEditView()
            }
            .onAppear { viewModel.loadCases(cases) }
            .onChange(of: cases) { _, newValue in viewModel.loadCases(newValue) }
            .onChange(of: viewModel.searchText) { _, _ in viewModel.loadCases(cases) }
        }
    }

    // MARK: - 列表

    private var listContent: some View {
        List {
            // Pipeline 统计条
            Section {
                pipelineStats
            }

            if viewModel.isFiltering {
                Section("\(viewModel.totalCount) Result(s)") {
                    ForEach(viewModel.casesByStage.flatMap(\.1)) { caseRecord in
                        caseRow(caseRecord)
                    }
                }
            } else {
                ForEach(viewModel.casesByStage, id: \.0) { stage, stageCases in
                    Section {
                        ForEach(stageCases) { caseRecord in
                            caseRow(caseRecord)
                        }
                    } header: {
                        HStack {
                            Image(systemName: stage.isActive ? "circle.fill" : "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(stage.isActive ? .orange : .green)
                            Text(stage.rawValue)
                            Spacer()
                            Text("\(stageCases.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Pipeline 看板（水平缩放）

    private var pipelineStats: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.pipelineCounts, id: \.0) { stage, count in
                    Button {
                        withAnimation {
                            viewModel.selectedStageFilter = (viewModel.selectedStageFilter == stage) ? nil : stage
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(count > 0 ? stage.isActive ? .orange : .green : .secondary)
                            Text(stage.rawValue)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedStageFilter == stage ? Color.accentColor.opacity(0.08) : .clear)
                        .clipShape(.rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func caseRow(_ caseRecord: CaseRecord) -> some View {
        NavigationLink {
            CaseDetailView(caseRecord: caseRecord)
        } label: {
            CaseRowView(caseRecord: caseRecord)
        }
        .swipeActions(edge: .trailing) {
            Button("Close", systemImage: "checkmark.seal") {
                closeCase(caseRecord)
            }
            .tint(.green)
        }
    }

    private func closeCase(_ caseRecord: CaseRecord) {
        withAnimation {
            caseRecord.caseStage = .closed
            caseRecord.closingDate = Date()
            try? modelContext.save()
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No cases yet")
                .font(.title3.weight(.medium))
            Text("Add your first case — criminal, civil, administrative...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddCase = true
            } label: {
                Label("Add your first case", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

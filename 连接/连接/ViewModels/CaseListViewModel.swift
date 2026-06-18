import Foundation
import SwiftUI

/// 案件列表的数据逻辑：Pipeline 看板分组 / 搜索 / 阶段筛选
@MainActor
@Observable
final class CaseListViewModel {

    var searchText = ""
    var selectedStageFilter: CaseStage? = nil
    var showOnlyActive = true

    // MARK: - 派生数据

    /// Pipeline 分组：按阶段分组的案件
    var casesByStage: [(CaseStage, [CaseRecord])] {
        let filtered = filteredCases
        let grouped = Dictionary(grouping: filtered) { $0.caseStage }
        return CaseStage.allCases.compactMap { stage in
            guard let cases = grouped[stage], !cases.isEmpty else { return nil }
            return (stage, cases.sorted { ($0.filingDate ?? .distantPast) > ($1.filingDate ?? .distantPast) })
        }
    }

    /// Pipeline 统计：每阶段案件数
    var pipelineCounts: [(CaseStage, Int)] {
        CaseStage.allCases.map { stage in
            let count = allCases.filter { $0.caseStage == stage }.count
            return (stage, count)
        }
    }

    /// 活跃案件数 / 已结案数
    var activeCount: Int {
        allCases.filter { $0.caseStage.isActive }.count
    }

    var closedCount: Int {
        allCases.filter { !$0.caseStage.isActive }.count
    }

    var totalCount: Int { filteredCases.count }

    var isFiltering: Bool { !searchText.isEmpty || selectedStageFilter != nil }

    // MARK: - Private

    private var allCases: [CaseRecord] = []

    private var filteredCases: [CaseRecord] {
        var result = allCases

        if showOnlyActive {
            result = result.filter { $0.caseStage.isActive }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { caseRecord in
                caseRecord.caseName.lowercased().contains(query)
                || (caseRecord.courtCaseNumber ?? "").lowercased().contains(query)
                || (caseRecord.internalCaseNumber ?? "").lowercased().contains(query)
                || (caseRecord.caseResult ?? "").lowercased().contains(query)
                || (caseRecord.acceptedOrganization?.name ?? "").lowercased().contains(query)
            }
        }

        if let stage = selectedStageFilter {
            result = result.filter { $0.caseStage == stage }
        }

        return result
    }

    func loadCases(_ cases: [CaseRecord]) {
        allCases = cases
    }
}

import Foundation

/// 搜索历史管理器——UserDefaults 持久化，最多 10 条，自动去重
@MainActor
final class SearchHistory {
    static let shared = SearchHistory()

    private let key = "search_history"
    private let maxCount = 10

    private init() {}

    /// 获取最近搜索记录
    var items: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// 添加一条搜索记录（去重 + 移到最前 + 截断）
    func add(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }

        var list = items
        // 去重：移除旧的同名记录
        list.removeAll { $0.caseInsensitiveCompare(q) == .orderedSame }
        // 插入到最前
        list.insert(q, at: 0)
        // 截断
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        UserDefaults.standard.set(list, forKey: key)
    }

    /// 删除单条记录
    func remove(_ query: String) {
        var list = items
        list.removeAll { $0 == query }
        UserDefaults.standard.set(list, forKey: key)
    }

    /// 清空全部历史
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

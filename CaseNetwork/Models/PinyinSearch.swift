import Foundation

// MARK: - 拼音搜索扩展

extension String {

    /// 将中文字符串转换为拼音（全拼 + 首字母）
    /// - Returns: (全拼字符串, 首字母字符串)，英文/数字原样保留
    ///
    /// 示例：
    /// ```swift
    /// "张三".pinyin → ("zhang san", "zs")
    /// "王律师".pinyin → ("wang lv shi", "wls")
    /// "CaseNetwork".pinyin → ("casenetwork", "casenetwork")
    /// ```
    var pinyin: (full: String, initial: String) {
        let mutable = NSMutableString(string: self)
        // CFStringTransform 将中文转为带声调的拉丁字母
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        // 去掉声调
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)

        let latin = (mutable as String).lowercased()

        // 从拼音字符串提取首字母
        let initials = latin
            .components(separatedBy: .whitespaces)
            .compactMap { $0.first }
            .map(String.init)
            .joined()

        return (latin, initials)
    }

    /// 判断搜索 query 是否匹配当前字符串（支持中文原文 + 拼音全拼 + 拼音首字母）
    /// - Parameter query: 搜索关键词（小写）
    /// - Returns: 是否匹配
    ///
    /// 匹配逻辑：
    /// 1. 原文包含 query（"张" 匹配 "张三"）
    /// 2. 拼音全拼包含 query（"zhang" 匹配 "张三"，"zhangsan" 匹配 "张三"）
    /// 3. 拼音首字母包含 query（"zs" 匹配 "张三"）
    func matchesPinyin(query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }

        // 1. 原文匹配（忽略大小写）
        if self.lowercased().contains(q) { return true }

        // 2. 拼音匹配
        let py = self.pinyin
        // 全拼去空格后匹配（支持 "zhangsan" 搜 "张三"）
        let fullNoSpace = py.full.replacingOccurrences(of: " ", with: "")
        if fullNoSpace.contains(q) { return true }
        // 首字母匹配（"zs" 搜 "张三"）
        if py.initial.contains(q) { return true }

        return false
    }
}

// MARK: - 多字段联合搜索

/// 联系人搜索辅助
extension Contact {
    /// 判断是否匹配搜索 query（姓名+手机+机构名+技能标签）
    func matchesSearchQuery(_ query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }

        if name.matchesPinyin(query: q) { return true }
        if let phone = phone, phone.contains(q) { return true }
        if let orgName = organization?.name, orgName.matchesPinyin(query: q) { return true }
        if let wechat = wechat, wechat.contains(q) { return true }
        if let email = email, email.lowercased().contains(q) { return true }
        if skillTags.contains(where: { $0.matchesPinyin(query: q) }) { return true }

        return false
    }
}

/// 案件搜索辅助
extension CaseRecord {
    /// 判断是否匹配搜索 query（案名+案号+机构名+结果+备注）
    func matchesSearchQuery(_ query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }

        if caseName.matchesPinyin(query: q) { return true }
        if let cn = courtCaseNumber, cn.lowercased().contains(q) { return true }
        if let icn = internalCaseNumber, icn.lowercased().contains(q) { return true }
        if let orgName = acceptedOrganization?.name, orgName.matchesPinyin(query: q) { return true }
        if let result = caseResult, result.matchesPinyin(query: q) { return true }
        if let notes = notes, notes.lowercased().contains(q) { return true }

        return false
    }
}

import Foundation

// MARK: - 数组 ↔ JSON 字符串 转换工具

/// SwiftData `@Model` 类不原生支持 `[Enum]` 或 `[String]` 直接存储。
/// 解决方案：用 `String`（JSON）作为底层存储，通过工具方法做类型转换。
/// 当 `AttributeTransformer` API 在 SwiftData 中稳定后，可迁移为原生 transformable。

enum JSONArrayTransformer {

    // MARK: - [String]

    static func encodeStringArray(_ array: [String]) -> String {
        guard let data = try? JSONEncoder().encode(array),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func decodeStringArray(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }

    // MARK: - [Int]

    static func encodeIntArray(_ array: [Int]) -> String {
        guard let data = try? JSONEncoder().encode(array),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func decodeIntArray(_ json: String) -> [Int] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return array
    }

    // MARK: - [ContactRole]

    static func encodeContactRoles(_ roles: [ContactRole]) -> String {
        let strings = roles.map(\.rawValue)
        return encodeStringArray(strings)
    }

    static func decodeContactRoles(_ json: String) -> [ContactRole] {
        decodeStringArray(json).compactMap(ContactRole.init(rawValue:))
    }

    // MARK: - [OrgRole]

    static func encodeOrgRoles(_ roles: [OrgRole]) -> String {
        let strings = roles.map(\.rawValue)
        return encodeStringArray(strings)
    }

    static func decodeOrgRoles(_ json: String) -> [OrgRole] {
        decodeStringArray(json).compactMap(OrgRole.init(rawValue:))
    }
}

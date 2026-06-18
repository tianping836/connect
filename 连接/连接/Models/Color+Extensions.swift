import SwiftUI

// MARK: - Hex 颜色初始化（自适应深色模式）

extension Color {
    /// 从十六进制字符串初始化颜色
    /// - Parameter hex: "#RRGGBB" 或 "RRGGBB" 格式
    /// - Note: 深色模式下自动提亮 30%，确保在深色背景上可读
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        // 浅色模式使用原色；深色模式提亮 30%
        let light = Color(red: r, green: g, blue: b)
        let dark = Color(
            red: r + (1.0 - r) * 0.30,
            green: g + (1.0 - g) * 0.30,
            blue: b + (1.0 - b) * 0.30
        )

        #if os(iOS)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark]) == .darkAqua
                ? NSColor(dark) : NSColor(light)
        })
        #endif
    }
}

// MARK: - 深色模式自适应角色颜色

extension Color {
    /// 角色标签颜色——深色模式下自动提亮，确保可读性
    /// - Parameter hex: 浅色模式下的十六进制颜色
    /// - Returns: 自适应颜色
    ///
    /// 策略：深色模式下将颜色向白色方向插值 30%，保持色相不变
    static func adaptiveRole(hex: String) -> Color {
        let rgb = hexToRGB(hex)
        // 浅色模式使用原色；深色模式提亮
        return Color(light: Color(red: rgb.r, green: rgb.g, blue: rgb.b),
                     dark: lighterColor(hex: hex, factor: 0.35))
    }

    /// 浅色/深色模式下的不同颜色
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark]) == .darkAqua
                ? NSColor(dark) : NSColor(light)
        })
        #endif
    }

    // MARK: 内部工具

    private static func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        return (
            r: Double((int >> 16) & 0xFF) / 255.0,
            g: Double((int >> 8) & 0xFF) / 255.0,
            b: Double(int & 0xFF) / 255.0
        )
    }

    /// 将颜色向白色方向插值
    private static func lighterColor(hex: String, factor: Double) -> Color {
        let rgb = hexToRGB(hex)
        let t = factor
        return Color(
            red: rgb.r + (1.0 - rgb.r) * t,
            green: rgb.g + (1.0 - rgb.g) * t,
            blue: rgb.b + (1.0 - rgb.b) * t
        )
    }
}

import Foundation
import LocalAuthentication
import SwiftUI
import Observation

/// 生物识别认证服务——Face ID / Touch ID / Optic ID
///
/// 用法：
/// ```swift
/// // 在 App 入口注册场景阶段监听
/// @Environment(\.scenePhase) private var scenePhase
///     .onChange(of: scenePhase) { _, newPhase in
///         if newPhase == .background { BiometricAuthService.shared.lock() }
///     }
/// // 在 WindowGroup 上叠加 AppLockView
///     .overlay { if auth.isAppLocked { AppLockView() } }
/// ```
@MainActor
@Observable
final class BiometricAuthService {

    static let shared = BiometricAuthService()

    // MARK: - 发布状态

    /// 当前是否锁定
    var isAppLocked = false

    /// 用户是否开启了应用锁
    var isAppLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key_appLockEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: key_appLockEnabled)
            if !newValue { isAppLocked = false }
        }
    }

    /// 锁定延迟策略：立即 (immediate) 或 离开后台 N 秒后 (delayed)
    var lockDelay: AppLockDelay {
        get {
            let raw = UserDefaults.standard.string(forKey: key_lockDelay) ?? ""
            return AppLockDelay(rawValue: raw) ?? .immediate
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key_lockDelay)
        }
    }

    // MARK: - 生物识别能力

    /// 当前设备支持的生物识别类型
    var biometryType: LABiometryType {
        var error: NSError?
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return ctx.biometryType
    }

    /// 人类可读的生物识别名称
    var biometryName: String {
        switch biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none:    return "设备密码"
        @unknown default: return "生物识别"
        }
    }

    /// 设备是否支持生物识别
    var isBiometryAvailable: Bool {
        biometryType != .none
    }

    // MARK: - 锁定 / 解锁

    /// 加锁（通常由场景阶段变化触发）
    func lock() {
        guard isAppLockEnabled else { return }

        switch lockDelay {
        case .immediate:
            isAppLocked = true
        case .after(let seconds):
            Task {
                try? await Task.sleep(for: .seconds(seconds))
                // 再次检查：用户可能在前台了
                guard isAppLockEnabled else { return }
                isAppLocked = true
            }
        }
    }

    /// 手动加锁（从设置页或其他入口）
    func lockNow() {
        guard isAppLockEnabled else { return }
        isAppLocked = true
    }

    /// 尝试解锁（弹出系统生物识别对话框）
    /// - Returns: 是否解锁成功
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // 不支持任何认证 → 用密码兜底
            return await authenticateWithPasscode(context: context)
        }

        let reason = "验证身份以解锁 CaseNetwork"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success { isAppLocked = false }
            return success
        } catch {
            // 用户取消或失败 → 回退到设备密码
            let code = (error as NSError).code
            if code == LAError.userFallback.rawValue
                || code == LAError.authenticationFailed.rawValue {
                return await authenticateWithPasscode(context: context)
            }
            return false
        }
    }

    // MARK: - 私有

    private func authenticateWithPasscode(context: LAContext) async -> Bool {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "输入设备密码以解锁 CaseNetwork"
            )
            if success { isAppLocked = false }
            return success
        } catch {
            return false
        }
    }

    private let key_appLockEnabled = "app_lock_enabled"
    private let key_lockDelay = "app_lock_delay"
}

// MARK: - 锁定延迟策略

enum AppLockDelay: RawRepresentable, CaseIterable, Hashable {
    case immediate
    case after(TimeInterval)

    // MARK: RawRepresentable
    var rawValue: String {
        switch self {
        case .immediate: return "immediate"
        case .after(let s): return "after_\(s)"
        }
    }

    init?(rawValue: String) {
        if rawValue == "immediate" { self = .immediate }
        else if rawValue.hasPrefix("after_"),
                let s = TimeInterval(rawValue.replacingOccurrences(of: "after_", with: "")) {
            self = .after(s)
        } else { return nil }
    }

    // MARK: CaseIterable
    static var allCases: [AppLockDelay] {
        [.immediate, .after(15), .after(60)]
    }

    var displayName: String {
        switch self {
        case .immediate: return "立即锁定"
        case .after(15): return "离开 15 秒后"
        case .after(60): return "离开 1 分钟后"
        default: return rawValue
        }
    }
}

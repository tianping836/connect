import SwiftUI

/// 生物识别锁屏遮罩——覆盖在 App 最上层
///
/// 当 BiometricAuthService.isAppLocked == true 时全屏显示。
/// 点击"解锁"按钮或自动弹出系统 Face ID / Touch ID 对话框。
struct AppLockView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var authFailed = false
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            // 毛玻璃背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // 图标
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.blue.gradient)
                    .padding(.bottom, 4)

                // 标题
                Text("连接已锁定")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("需要 \(BiometricAuthService.shared.biometryName) 验证身份")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 解锁按钮
                Button {
                    authenticate()
                } label: {
                    Group {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: BiometricAuthService.shared.biometryType == .faceID
                                      ? "faceid" : "touchid")
                                Text("解锁")
                            }
                        }
                    }
                    .frame(width: 160, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isAuthenticating)
                .keyboardShortcut(.defaultAction)  // ↩ 键触发

                // 错误提示
                if authFailed {
                    Text("验证失败，请重试")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.8))
                    .shadow(radius: 20)
            )
        }
        .onAppear {
            // 自动触发认证
            authenticate()
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authFailed = false

        Task {
            let success = await BiometricAuthService.shared.authenticate()
            isAuthenticating = false
            withAnimation(.easeInOut(duration: 0.2)) {
                authFailed = !success
            }
        }
    }
}

#Preview {
    AppLockView()
}

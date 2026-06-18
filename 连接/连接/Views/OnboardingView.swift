import SwiftUI

/// 首次启动引导页——欢迎 + 核心功能介绍 + 快速开始
/// iOS: 分页滑动 | macOS: 单页滚动
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddContact = false
    @State private var showAddCase = false

    var body: some View {
        Group {
            #if os(macOS)
            ScrollView {
                VStack(spacing: 32) {
                    welcomeSection
                        .padding(.top, 40)
                    Divider().padding(.horizontal, 60)
                    featuresSection
                    Divider().padding(.horizontal, 60)
                    quickStartSection
                        .padding(.bottom, 40)
                }
            }
            #else
            TabView {
                welcomeSection
                    .tag(0)
                featuresSection
                    .tag(1)
                quickStartSection
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            #endif
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showAddContact) {
            ContactEditView()
        }
        .sheet(isPresented: $showAddCase) {
            CaseEditView()
        }
    }

    // MARK: - 欢迎区

    private var welcomeSection: some View {
        VStack(spacing: 28) {
            #if os(iOS)
            Spacer().frame(height: 40)
            #endif

            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 100, height: 100)
                Image(systemName: "scale.3d")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("欢迎使用连接")
                    .font(.largeTitle.weight(.bold))
                Text("案件与人脉，一网打尽")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            #if os(iOS)
            Spacer()
            Text("滑动继续 →")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
            #endif
        }
    }

    // MARK: - 功能介绍区

    private var featuresSection: some View {
        VStack(spacing: 32) {
            Text("三大维度，一张网络")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 24) {
                featureRow(
                    icon: "magnifyingglass", color: .blue,
                    title: "搜一个案件 → 看全部参与人",
                    subtitle: "法官、检察官、对方律师、当事人——全部参与人及其角色一目了然。"
                )
                featureRow(
                    icon: "person.2.fill", color: .green,
                    title: "搜一个人 → 看全部关联案件",
                    subtitle: "所有案件、机构、介绍人链条。当事人与经办人员清晰区分。"
                )
                featureRow(
                    icon: "calendar", color: .orange,
                    title: "法庭日历与提醒",
                    subtitle: "月视图 + 11 种事件颜色区分。开庭前自动推送通知。"
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 快速开始区

    private var quickStartSection: some View {
        VStack(spacing: 24) {
            Text("准备好了吗？")
                .font(.title.weight(.bold))

            Text("添加你的第一个人脉或案件。\n之后随时可以导入更多。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                Button {
                    showAddContact = true
                } label: {
                    Label("添加第一个人脉", systemImage: "person.badge.plus")
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showAddCase = true
                } label: {
                    Label("添加第一个案件", systemImage: "doc.badge.plus")
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                dismiss()
            } label: {
                Text("先跳过 →")
                    .font(.body.weight(.medium))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 功能行

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif

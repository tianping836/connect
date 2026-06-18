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
                Text("Welcome to CaseNetwork")
                    .font(.largeTitle.weight(.bold))
                Text("Your case-contact intelligence")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            #if os(iOS)
            Spacer()
            Text("Swipe to continue →")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
            #endif
        }
    }

    // MARK: - 功能介绍区

    private var featuresSection: some View {
        VStack(spacing: 32) {
            Text("Three dimensions,\none network")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 24) {
                featureRow(
                    icon: "magnifyingglass", color: .blue,
                    title: "Search a case → see everyone involved",
                    subtitle: "Judges, prosecutors, opposing counsel, clients — all participants and their roles."
                )
                featureRow(
                    icon: "person.2.fill", color: .green,
                    title: "Search a person → see every related case",
                    subtitle: "All cases, organizations, referral chains. Client vs official, clearly separated."
                )
                featureRow(
                    icon: "calendar", color: .orange,
                    title: "Court calendar with reminders",
                    subtitle: "Month view. 11 event types color-coded. Push notifications before hearings."
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 快速开始区

    private var quickStartSection: some View {
        VStack(spacing: 24) {
            Text("Ready to start?")
                .font(.title.weight(.bold))

            Text("Add your first contact or case.\nYou can always import more later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                Button {
                    showAddContact = true
                } label: {
                    Label("Add your first contact", systemImage: "person.badge.plus")
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showAddCase = true
                } label: {
                    Label("Add your first case", systemImage: "doc.badge.plus")
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                dismiss()
            } label: {
                Text("Skip for now →")
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

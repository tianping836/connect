import SwiftUI

/// 某日事件列表——从日历格点击进入
struct DayEventsSheet: View {
    let date: Date
    let events: [KeyEvent]

    @Environment(\.dismiss) private var dismiss
    @State private var showAddEvent = false

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No events",
                        systemImage: "calendar",
                        description: Text(date.formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: "zh_CN"))))
                    )
                } else {
                    List {
                        ForEach(events) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: CalendarViewModel.colorHex(for: event.eventType)))
                                        .frame(width: 8, height: 8)

                                    Text(event.eventType.rawValue)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color(hex: CalendarViewModel.colorHex(for: event.eventType)))

                                    Spacer()

                                    if event.reminderEnabled {
                                        Image(systemName: "bell.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }

                                Text(event.title)
                                    .font(.subheadline.weight(.medium))

                                if let detail = event.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let caseName = event.caseRecord?.caseName {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.text")
                                            .font(.caption2)
                                        Text(caseName)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle(date.formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: "zh_CN"))))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddEvent = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                KeyEventEditView(preselectedDate: date)
            }
        }
    }
}

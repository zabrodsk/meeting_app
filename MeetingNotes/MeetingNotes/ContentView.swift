import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hub: HubClient
    @EnvironmentObject var recorder: AudioRecorder
    @EnvironmentObject var queue: UploadQueue
    @Environment(\.colorScheme) private var colorScheme

    private var screenBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.04, green: 0.04, blue: 0.04)
            : Color(red: 0.98, green: 0.98, blue: 0.99)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                screenBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !hub.isConfigured {
                        Text("Configure hub in Settings to upload recordings.")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 0)

                    AIVoiceInput()

                    Spacer(minLength: 0)

                    QueueStatusView()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Meeting Notes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(screenBackground, for: .navigationBar)
            #elseif os(macOS)
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbarBackground(screenBackground, for: .windowToolbar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        hub.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $hub.showSettings) {
                SettingsView()
            }
            .onAppear {
                queue.setHub(hub)
                queue.load()
            }
        }
    }
}

struct QueueStatusView: View {
    @EnvironmentObject var queue: UploadQueue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if queue.items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Queue")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                ForEach(queue.items) { item in
                    HStack {
                        Image(systemName: statusIcon(item.status))
                            .foregroundStyle(statusColor(item.status))
                        Text(item.fileName)
                            .lineLimit(1)
                            .foregroundStyle(.primary.opacity(0.9))
                        Spacer()
                        Text(item.statusLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func statusIcon(_ status: UploadItem.Status) -> String {
        switch status {
        case .queued: "clock"
        case .uploading: "arrow.up.circle"
        case .processing: "gearshape.2"
        case .done: "checkmark.circle.fill"
        case .failed: "exclamationmark.circle.fill"
        }
    }

    private func statusColor(_ status: UploadItem.Status) -> Color {
        switch status {
        case .queued: Color.primary.opacity(0.45)
        case .uploading: .cyan
        case .processing: .orange
        case .done: .green
        case .failed: .red
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HubClient())
        .environmentObject(AudioRecorder())
        .environmentObject(UploadQueue())
}

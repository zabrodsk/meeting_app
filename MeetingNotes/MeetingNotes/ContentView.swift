import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hub: HubClient
    @EnvironmentObject var recorder: AudioRecorder
    @EnvironmentObject var queue: UploadQueue

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !hub.isConfigured {
                        Text("Configure hub in Settings to upload recordings.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.45))
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
            #endif
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        hub.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .preferredColorScheme(.dark)
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

    var body: some View {
        if queue.items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Queue")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.9))
                ForEach(queue.items) { item in
                    HStack {
                        Image(systemName: statusIcon(item.status))
                            .foregroundStyle(statusColor(item.status))
                        Text(item.fileName)
                            .lineLimit(1)
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text(item.statusLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
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
        case .queued: .white.opacity(0.45)
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

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hub: HubClient
    @EnvironmentObject var recorder: AudioRecorder
    @EnvironmentObject var queue: UploadQueue

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !hub.isConfigured {
                    Text("Configure hub in Settings to upload recordings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if recorder.isRecording {
                    RecordingView()
                } else {
                    IdleView()
                }
                QueueStatusView()
            }
            .padding()
            .navigationTitle("Meeting Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        hub.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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

struct RecordingView: View {
    @EnvironmentObject var recorder: AudioRecorder
    @EnvironmentObject var queue: UploadQueue

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            Text("Recording")
                .font(.headline)
            Text(recorder.formattedDuration)
                .font(.title2.monospacedDigit())
            Button("Stop", role: .destructive) {
                recorder.stop { url in
                    if let url {
                        queue.enqueue(url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct IdleView: View {
    @EnvironmentObject var recorder: AudioRecorder

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Tap to record")
                .font(.headline)
            Button("Record") {
                recorder.start()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                ForEach(queue.items) { item in
                    HStack {
                        Image(systemName: statusIcon(item.status))
                            .foregroundStyle(statusColor(item.status))
                        Text(item.fileName)
                            .lineLimit(1)
                        Spacer()
                        Text(item.statusLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.regularMaterial)
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
        case .queued: .secondary
        case .uploading: .blue
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

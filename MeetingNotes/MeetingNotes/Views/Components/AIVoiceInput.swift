import SwiftUI

/// Dark, minimal voice capture UI (idle: mic + dim bars; recording: spinning square + animated waveform).
struct AIVoiceInput: View {
    @EnvironmentObject private var recorder: AudioRecorder
    @EnvironmentObject private var queue: UploadQueue

    var visualizerBars: Int = 48

    @State private var idleBarPhase: CGFloat = 0

    private var isRecording: Bool { recorder.isRecording }

    private var elapsedSeconds: Int {
        Int(recorder.duration.rounded(.down))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            VStack(spacing: 0) {
                Button(action: toggleRecording) {
                    ZStack {
                        if isRecording {
                            spinningIndicator(date: timeline.date)
                        } else {
                            Image(systemName: "mic")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .symbolRenderingMode(.monochrome)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.25), value: isRecording)

                Text(formatTime(elapsedSeconds))
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundStyle(isRecording ? Color.white.opacity(0.85) : Color.white.opacity(0.35))
                    .padding(.top, 10)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: elapsedSeconds)

                visualizerRow(time: t)
                    .padding(.top, 14)
                    .frame(height: 28)

                Text(isRecording ? "Listening..." : promptText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                idleBarPhase = 1
            }
        }
    }

    private var promptText: String {
        #if os(iOS)
        "Tap to speak"
        #else
        "Click to speak"
        #endif
    }

    private func spinningIndicator(date: Date) -> some View {
        let seconds = date.timeIntervalSinceReferenceDate
        let degrees = (seconds.truncatingRemainder(dividingBy: 3.0)) / 3.0 * 360.0
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .rotationEffect(.degrees(degrees))
    }

    private func visualizerRow(time: Double) -> some View {
        let n = visualizerBars
        return HStack(alignment: .center, spacing: 3) {
            ForEach(0..<n, id: \.self) { i in
                barView(index: i, time: time, total: n)
            }
        }
        .frame(maxWidth: 280)
    }

    private func barView(index: Int, time: Double, total: Int) -> some View {
        let center = Double(total - 1) / 2.0
        let dist = abs(Double(index) - center) / max(center, 1)
        let envelope = 1.0 - dist * dist

        let heightFraction: CGFloat
        if isRecording {
            let wobble = sin(time * 5.0 + Double(index) * 0.45) * 0.5 + 0.5
            let pulse = sin(time * 2.8 + Double(index) * 0.12) * 0.35 + 0.65
            let h = (0.12 + 0.88 * wobble * pulse * envelope)
            heightFraction = CGFloat(max(0.08, min(1.0, h)))
        } else {
            let breathe = 0.35 + 0.15 * sin(Double(idleBarPhase) * .pi + Double(index) * 0.2)
            heightFraction = CGFloat(0.06 + 0.06 * breathe)
        }

        let barH = 26 * heightFraction
        return RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.white.opacity(isRecording ? 0.55 : 0.12))
            .frame(width: 2, height: max(3, barH))
            .animation(.easeOut(duration: 0.12), value: heightFraction)
    }

    private func toggleRecording() {
        if isRecording {
            recorder.stop { url in
                if let url {
                    queue.enqueue(url)
                }
            }
        } else {
            recorder.start()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview("AIVoiceInput") {
    ZStack {
        Color.black.ignoresSafeArea()
        AIVoiceInput()
            .environmentObject(AudioRecorder())
            .environmentObject(UploadQueue())
    }
    .preferredColorScheme(.dark)
}

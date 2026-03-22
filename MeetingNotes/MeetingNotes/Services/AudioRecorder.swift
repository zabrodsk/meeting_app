import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var duration: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var tempURL: URL?

    var formattedDuration: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }

    func start() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            return
        }
        #endif

        let dir = FileManager.default.temporaryDirectory
        let name = "meeting_\(Date().timeIntervalSince1970).m4a"
        tempURL = dir.appendingPathComponent(name)
        guard let url = tempURL else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            duration = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.duration = self?.recorder?.currentTime ?? 0
                }
            }
            RunLoop.current.add(timer!, forMode: .common)
        } catch {
            isRecording = false
        }
    }

    func stop(completion: @escaping (URL?) -> Void) {
        timer?.invalidate()
        timer = nil
        guard let rec = recorder else {
            completion(nil)
            return
        }
        rec.stop()
        let url = tempURL
        tempURL = nil
        recorder = nil
        isRecording = false
        duration = 0

        let destDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        let dest = destDir.appendingPathComponent(url?.lastPathComponent ?? "recording.m4a")
        if let url {
            do {
                try FileManager.default.moveItem(at: url, to: dest)
                completion(dest)
            } catch {
                completion(url)
            }
        } else {
            completion(nil)
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}

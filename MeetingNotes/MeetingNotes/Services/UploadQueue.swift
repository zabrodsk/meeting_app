import Foundation

@MainActor
final class UploadQueue: ObservableObject {
    @Published var items: [UploadItem] = []

    private let maxRetries = 5
    private let retryDelays: [TimeInterval] = [30, 60, 300, 600, 1800]
    private var hub: HubClient?
    private var processing = false

    private let queueDir: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("UploadQueue", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func setHub(_ hub: HubClient) {
        self.hub = hub
    }

    func enqueue(_ url: URL) {
        let item = UploadItem(id: UUID(), fileURL: url, status: .queued, retryCount: 0)
        items.append(item)
        persist()
        processNext()
    }

    private func processNext() {
        guard !processing, let hub else { return }
        guard let idx = items.firstIndex(where: { $0.status == .queued }) else { return }
        processing = true
        let item = items[idx]
        items[idx].status = .uploading

        Task {
            do {
                let jobId = try await hub.upload(audioURL: item.fileURL)
                items[idx].jobId = jobId
                items[idx].status = .processing
                await pollUntilDone(idx: idx, hub: hub)
            } catch {
                items[idx].status = .failed
                items[idx].error = error.localizedDescription
                scheduleRetry(idx: idx)
            }
            processing = false
            persist()
            processNext()
        }
    }

    private func pollUntilDone(idx: Int, hub: HubClient) async {
        guard let jobId = items[idx].jobId else { return }
        for _ in 0..<600 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                let (status, notionURL) = try await hub.pollJobStatus(jobId: jobId)
                if status == "done" {
                    items[idx].status = .done
                    items[idx].notionURL = notionURL
                    return
                }
                if status == "failed" {
                    items[idx].status = .failed
                    items[idx].error = "Hub processing failed"
                    return
                }
            } catch {
                continue
            }
        }
        items[idx].status = .failed
        items[idx].error = "Timeout"
    }

    private func scheduleRetry(idx: Int) {
        let retryCount = items[idx].retryCount
        guard retryCount < maxRetries else { return }
        items[idx].retryCount = retryCount + 1
        let delay = retryDelays[min(retryCount, retryDelays.count - 1)]
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run {
                items[idx].status = .queued
                items[idx].error = nil
                processNext()
            }
        }
    }

    private func persist() {
        let file = queueDir.appendingPathComponent("queue.json")
        let encodable = items.map { i in
            [
                "id": i.id.uuidString,
                "url": i.fileURL.path,
                "jobId": i.jobId ?? "",
                "status": String(describing: i.status),
                "retryCount": i.retryCount,
            ] as [String: Any]
        }
        if let data = try? JSONSerialization.data(withJSONObject: encodable) {
            try? data.write(to: file)
        }
    }

    func load() {
        let file = queueDir.appendingPathComponent("queue.json")
        guard let data = try? Data(contentsOf: file),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        items = arr.compactMap { dict -> UploadItem? in
            guard let idStr = dict["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let path = dict["url"] as? String else { return nil }
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            let statusStr = dict["status"] as? String ?? "queued"
            let status: UploadItem.Status = {
                switch statusStr {
                case "queued": .queued
                case "uploading": .queued
                case "processing": .queued
                case "done": .done
                default: .queued
                }
            }()
            return UploadItem(
                id: id,
                fileURL: url,
                jobId: (dict["jobId"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                status: status,
                retryCount: dict["retryCount"] as? Int ?? 0
            )
        }
    }
}

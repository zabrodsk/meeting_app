import Foundation

struct UploadItem: Identifiable {
    let id: UUID
    let fileURL: URL
    var jobId: String?
    var status: Status
    var error: String?
    var notionURL: String?
    var retryCount: Int

    var fileName: String { fileURL.lastPathComponent }
    var statusLabel: String {
        switch status {
        case .queued: "Queued"
        case .uploading: "Uploading…"
        case .processing: "Processing…"
        case .done: "Saved to Notion"
        case .failed: error ?? "Failed"
        }
    }

    enum Status {
        case queued
        case uploading
        case processing
        case done
        case failed
    }
}

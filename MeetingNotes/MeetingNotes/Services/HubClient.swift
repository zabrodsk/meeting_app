import Foundation

@MainActor
final class HubClient: ObservableObject {
    @Published var showSettings = false
    @Published var isConfigured: Bool = false

    private var config: HubConfig?

    init() {
        config = HubConfig.load()
        isConfigured = config != nil
    }

    func configure(baseURL: String, apiKey: String) {
        var c = HubConfig(baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines), apiKey: apiKey)
        if !c.baseURL.hasSuffix("/") { c.baseURL += "/" }
        c.save()
        config = c
        isConfigured = true
    }

    func upload(audioURL: URL) async throws -> String {
        guard let cfg = config else { throw HubError.notConfigured }
        let url = URL(string: cfg.baseURL + "jobs")!
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(cfg.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let data = try Data(contentsOf: audioURL)
        let fileName = audioURL.lastPathComponent
        let mimeType = "audio/m4a"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (respData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HubError.invalidResponse }
        guard http.statusCode == 200 else {
            throw HubError.serverError(status: http.statusCode, body: String(data: respData, encoding: .utf8))
        }
        let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any]
        guard let jobId = json?["job_id"] as? String else { throw HubError.invalidResponse }
        return jobId
    }

    func pollJobStatus(jobId: String) async throws -> (status: String, notionURL: String?) {
        guard let cfg = config else { throw HubError.notConfigured }
        let url = URL(string: cfg.baseURL + "jobs/\(jobId)")!
        var request = URLRequest(url: url)
        request.setValue(cfg.apiKey, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HubError.invalidResponse
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let status = json?["status"] as? String ?? "unknown"
        let notionURL = json?["notion_url"] as? String
        return (status, notionURL)
    }
}

enum HubError: LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(status: Int, body: String?)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Hub not configured. Add hub URL and API key in Settings."
        case .invalidResponse: "Invalid response from hub."
        case .serverError(let status, let body): "Server error \(status): \(body ?? "unknown")"
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var hub: HubClient
    @Environment(\.dismiss) var dismiss

    @State private var baseURL: String = ""
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Hub URL", text: $baseURL, prompt: Text("https://mini.your-tailnet.ts.net:8000"))
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                } header: {
                    Text("Mac Mini Hub")
                } footer: {
                    Text("Use your Tailscale MagicDNS hostname (e.g. mini.your-tailnet.ts.net) and the API key from the hub config.")
                }
                Section {
                    Button("Save") {
                        hub.configure(baseURL: baseURL, apiKey: apiKey)
                        dismiss()
                    }
                    .disabled(baseURL.isEmpty || apiKey.isEmpty)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let cfg = HubConfig.load() {
                    baseURL = cfg.baseURL
                    apiKey = cfg.apiKey
                }
            }
        }
    }
}

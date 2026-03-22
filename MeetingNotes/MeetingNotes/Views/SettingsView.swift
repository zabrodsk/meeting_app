import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var hub: HubClient
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage("appAppearance") private var appearanceRaw = AppAppearance.dark.rawValue

    @State private var baseURL: String = ""
    @State private var apiKey: String = ""

    private var selectedAppearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRaw) ?? .dark },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var pageBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.04, green: 0.04, blue: 0.04)
            : Color(red: 0.99, green: 0.99, blue: 1.0)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color(red: 0.63, green: 0.63, blue: 0.68) : Color(red: 0.45, green: 0.45, blue: 0.5)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    appearanceSection

                    sectionDivider

                    hubSection

                    HStack {
                        Spacer()
                        Button {
                            hub.configure(baseURL: baseURL, apiKey: apiKey)
                            dismiss()
                        } label: {
                            Text("Save changes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(borderColor, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(baseURL.isEmpty || apiKey.isEmpty)
                        .opacity(baseURL.isEmpty || apiKey.isEmpty ? 0.45 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 32)
                }
            }
            .background(pageBackground)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
            #if os(iOS)
            .toolbarBackground(pageBackground, for: .navigationBar)
            #elseif os(macOS)
            .toolbarBackground(pageBackground, for: .windowToolbar)
            #endif
            .onAppear {
                if let cfg = HubConfig.load() {
                    baseURL = cfg.baseURL
                    apiKey = cfg.apiKey
                }
            }
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(borderColor.opacity(0.6))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private var appearanceSection: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appearance")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Light, dark, or match the system.")
                            .font(.system(size: 13))
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Picker("", selection: selectedAppearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appearance")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Light, dark, or match the system.")
                            .font(.system(size: 13))
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("", selection: selectedAppearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var hubSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            hubFieldRow(
                title: "Hub URL",
                subtitle: "Tailscale MagicDNS or LAN address, with port.",
                content: {
                    TextField("", text: $baseURL, prompt: Text("https://mini.example.ts.net:8000/").foregroundStyle(secondaryText))
                        .textContentType(.URL)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                }
            )

            sectionDivider
                .padding(.vertical, 8)

            hubFieldRow(
                title: "API key",
                subtitle: "Same value as HUB_API_KEY on your Mac mini.",
                content: {
                    SecureField("", text: $apiKey, prompt: Text("Required").foregroundStyle(secondaryText))
                        .textContentType(.password)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                }
            )
        }
    }

    private func hubFieldRow<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(minWidth: 120, maxWidth: 220, alignment: .leading)

                    content()
                        .frame(minWidth: 180, maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(HubClient())
}

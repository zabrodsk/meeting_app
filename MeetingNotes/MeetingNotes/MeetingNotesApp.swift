import SwiftUI

@main
struct MeetingNotesApp: App {
    @StateObject private var hub = HubClient()
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var queue = UploadQueue()

    @AppStorage("appAppearance") private var appearanceRaw = AppAppearance.dark.rawValue

    private var resolvedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .dark
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hub)
                .environmentObject(recorder)
                .environmentObject(queue)
                .preferredColorScheme(resolvedAppearance.preferredColorScheme)
        }
    }
}

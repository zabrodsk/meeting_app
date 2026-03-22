import SwiftUI

@main
struct MeetingNotesApp: App {
    @StateObject private var hub = HubClient()
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var queue = UploadQueue()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hub)
                .environmentObject(recorder)
                .environmentObject(queue)
        }
    }
}

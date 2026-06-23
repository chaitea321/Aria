import AVFoundation
import SwiftUI

@main
struct AriaApp: App {
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default, options: [.mixWithOthers]
            )
        } catch {
            print("AriaApp: failed to set audio session category: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

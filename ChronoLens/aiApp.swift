import ParseSwift
import SwiftUI

@main
struct aiApp: App {
    @State private var appState = AppState()

    init() {
        ParseSwift.initialize(
            applicationId: "7K2lAKYANjg2OSU6iRtKb4B9aA5H1B1OedmC5rE4",
            clientKey: "YttjCg6fFOBz3OK916NRrLHcxSlzIX8zkGQFliA4",
            serverURL: URL(string: "https://parseapi.back4app.com")!,
            usingDataProtectionKeychain: false
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

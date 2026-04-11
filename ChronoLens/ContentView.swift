import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab = 0

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.isLoggedIn {
                TabView(selection: $selectedTab) {
                    ExploreView()
                        .tabItem {
                            Label("Explore", systemImage: "binoculars")
                        }
                        .tag(0)

                    CollectionView()
                        .tabItem {
                            Label("Collection", systemImage: "square.stack")
                        }
                        .tag(1)

                    CommunityFeedView()
                        .tabItem {
                            Label("Community", systemImage: "person.3")
                        }
                        .tag(2)
                }
            } else {
                WelcomeView(appState: appState)
            }
        }
        .onAppear {
            appState.checkLoginStatus()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}

import SwiftUI

struct WelcomeView: View {
    var appState: AppState
    @State private var showSignUp = false
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "binoculars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("ChronoLens")
                        .font(.largeTitle.bold())

                    Text("Discover the history behind\nlandmarks, buildings, and artwork\naround you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Log In") {
                            showLogin = true
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 30)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(appState: appState)
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView(appState: appState)
            }
        }
    }
}

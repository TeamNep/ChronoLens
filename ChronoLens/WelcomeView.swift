import SwiftUI

enum AuthScreen {
    case login
    case signUp
}

struct WelcomeView: View {
    var appState: AppState
    @State private var navPath: [AuthScreen] = []
    @State private var appeared = false

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)

                        Image(systemName: "binoculars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 10) {
                        Text("ChronoLens")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Discover the history behind\nlandmarks, buildings, and artwork\naround you.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                Spacer()
                Spacer()

                VStack(spacing: 16) {
                    Button {
                        navPath = [.signUp]
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .blue.opacity(0.25), radius: 8, y: 4)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Log In") {
                            navPath = [.login]
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 50)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .padding(.horizontal, 30)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appeared = true
                }
            }
            .navigationDestination(for: AuthScreen.self) { screen in
                switch screen {
                case .login:
                    LoginView(appState: appState, onSwitchToSignUp: {
                        navPath = [.signUp]
                    })
                case .signUp:
                    SignUpView(appState: appState, onSwitchToLogin: {
                        navPath = [.login]
                    })
                }
            }
        }
    }
}

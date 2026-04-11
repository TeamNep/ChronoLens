import ParseSwift
import SwiftUI

struct LoginView: View {
    var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back")
                        .font(.largeTitle.bold())
                    Text("Sign in to continue exploring.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    LabeledField(label: "USERNAME", placeholder: "johndoe", text: $username)
                        .autocapitalization(.none)
                    LabeledField(label: "PASSWORD", placeholder: "........", text: $password, isSecure: true)

                    HStack {
                        Spacer()
                        Button("Forgot Password?") {}
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    login()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        ChronoUser.login(username: username, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                appState.onLoginSuccess()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

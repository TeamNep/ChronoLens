import ParseSwift
import SwiftUI

struct LoginView: View {
    var appState: AppState
    @Environment(\.dismiss) var dismiss
    var onSwitchToSignUp: (() -> Void)? = nil

    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome Back")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Sign in to continue exploring.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 18) {
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
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.callout)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    login()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .blue.opacity(0.2), radius: 6, y: 3)
                .disabled(isLoading)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        onSwitchToSignUp?()
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
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

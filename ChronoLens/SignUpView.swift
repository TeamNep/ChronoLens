import ParseSwift
import SwiftUI

struct SignUpView: View {
    var appState: AppState
    @Environment(\.dismiss) var dismiss
    var onSwitchToLogin: (() -> Void)? = nil

    @State private var fullName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Start exploring history.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 18) {
                    LabeledField(label: "FULL NAME", placeholder: "John Doe", text: $fullName)
                    LabeledField(label: "EMAIL", placeholder: "john@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    LabeledField(label: "USERNAME", placeholder: "@johndoe", text: $username)
                        .autocapitalization(.none)
                    LabeledField(label: "PASSWORD", placeholder: "........", text: $password, isSecure: true)
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
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Sign Up")
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
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Log In") {
                        onSwitchToLogin?()
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

    private func signUp() {
        guard !fullName.isEmpty, !email.isEmpty, !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        var user = ChronoUser()
        user.username = username
        user.email = email
        user.password = password
        user.fullName = fullName

        user.signup { result in
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

struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(0.5)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                TextField(placeholder, text: $text)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

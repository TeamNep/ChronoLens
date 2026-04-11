import ParseSwift
import SwiftUI

struct SignUpView: View {
    var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Start exploring history.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
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
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Sign Up")
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
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Log In") {
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
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

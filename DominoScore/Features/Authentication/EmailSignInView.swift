//
//  EmailSignInView.swift
//  DominoScore
//

import SwiftUI

/// Tela de login / cadastro com e-mail e senha.
struct EmailSignInView: View {
    var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isCreatingAccount = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Campos do formulário
            VStack(spacing: 12) {
                if isCreatingAccount {
                    TextField("Nome", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }

                TextField("E-mail", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Senha", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
            }

            // Mensagem de erro
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Botão principal
            Button {
                Task { await submit() }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(isCreatingAccount ? "Criar Conta" : "Entrar")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!isFormValid || isLoading)

            // Alternar entre login e cadastro
            Button {
                withAnimation {
                    isCreatingAccount.toggle()
                    errorMessage = nil
                }
            } label: {
                if isCreatingAccount {
                    Text("Já tem conta? **Entre aqui**")
                } else {
                    Text("Não tem conta? **Cadastre-se**")
                }
            }
            .font(.subheadline)

            Spacer()
        }
        .padding()
        .navigationTitle(isCreatingAccount ? "Criar Conta" : "Entrar")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        let nameValid = !isCreatingAccount || !name.trimmingCharacters(in: .whitespaces).isEmpty
        return emailValid && passwordValid && nameValid
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil

        do {
            if isCreatingAccount {
                try await authService.createAccount(
                    email: email,
                    password: password,
                    name: name.trimmingCharacters(in: .whitespaces)
                )
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview("Login") {
    NavigationStack {
        EmailSignInView(authService: AuthService())
    }
}

#Preview("Cadastro") {
    NavigationStack {
        EmailSignInView(authService: AuthService())
    }
}

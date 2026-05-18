//
//  AuthenticationView.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 05/05/26.
//

import SwiftUI
import AuthenticationServices

/// Tela inicial de autenticação — escolha de método de login.
struct AuthenticationView: View {
    @Environment(Coordinator.self) private var coordinator
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    /// Detecta o status de light mode do sistema
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / título
            VStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("DominoScore")
                    .font(.largeTitle.bold())

                Text("Entre para começar a jogar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Métodos de autenticação
            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .cornerRadius(12)
                .id(colorScheme)
                .overlay {
                    // Invisible button that intercepts taps to use our async flow
                    Button {
                        Task { await handleAppleSignIn() }
                    } label: {
                        Color.clear
                    }
                    .disabled(isLoading)
                }

                Button {
                    coordinator.navigate(to: .auth(.emailSignIn))
                } label: {
                    Label("Continuar com E-mail", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func handleAppleSignIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await coordinator.authService?.signInWithApple()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled — no error message needed
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AuthenticationView()
            .environment(Coordinator())
    }
}

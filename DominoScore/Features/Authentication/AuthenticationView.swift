//
//  AuthenticationView.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 05/05/26.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> some ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: type, style: style)
    }
    
    // MARK: diferente do tutorial
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

/// Tela inicial de autenticação — escolha de método de login.
struct AuthenticationView: View {
    @Environment(Coordinator.self) private var coordinator
    
    
    
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
            signInWithEmail
            
            SignInWithAppleButtonViewRepresentable(type: .continue, style: .white)
                .frame(height: 50)
                .allowsHitTesting(false)


            Spacer()
        }
        .padding()
    }
    
    private var signInWithEmail: some View {
        VStack(spacing: 12) {
            Button {
                coordinator.navigate(to: .auth(.emailSignIn))
            } label: {
                Label("Continuar com E-mail", systemImage: "envelope.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
    }
}

#Preview {
    NavigationStack {
        AuthenticationView()
            .environment(Coordinator())
    }
}

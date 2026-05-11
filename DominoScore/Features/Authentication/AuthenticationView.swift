//
//  AuthenticationView.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 05/05/26.
//

import SwiftUI

/// Tela inicial de autenticação — escolha de método de login.
struct AuthenticationView: View {
    @Environment(Coordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / título
            VStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 64))
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
                Button {
                    coordinator.navigate(to: .auth(.emailSignIn))
                } label: {
                    Label("Continuar com E-mail", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        AuthenticationView()
            .environment(Coordinator(authService: .init()))
    }
}



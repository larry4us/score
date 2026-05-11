//
//  AuthenticationView.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 05/05/26.
//

import SwiftUI

/// Tela inicial de autenticação — escolha de método de login.
struct AuthenticationView: View {
    //var authService: AuthService
    var coordinator: Coordinator

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

                // Placeholder para métodos futuros
                // Button {
                //     coordinator.navigate(to: .googleSignIn)
                // } label: {
                //     Label("Continuar com Google", systemImage: "g.circle.fill")
                //         .frame(maxWidth: .infinity)
                // }
                // .buttonStyle(.bordered)
                // .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthenticationView(coordinator: .init(authService: .init()      ))
        .environment(Coordinator(authService: .init()))
}



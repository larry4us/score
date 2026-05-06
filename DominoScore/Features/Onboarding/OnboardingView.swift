//
//  OnboardingView.swift
//  DominoScore
//

import SwiftUI

/// Welcome screen where the user enters their display name.
struct OnboardingView: View {
    @State private var playerName = ""
    var onComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "dice")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("DominoScore")
                .font(.largeTitle.bold())

            Text("Acompanhe o placar das suas partidas de domino.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Seu nome", text: $playerName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button("Continuar") {
                onComplete(playerName)
            }
            .buttonStyle(.borderedProminent)
            .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView { name in
        print("Name: \(name)")
    }
}

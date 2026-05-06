//
//  LobbyView.swift
//  DominoScore
//

import SwiftUI

/// Waiting room before the game starts. Shows participants and session code.
struct LobbyView: View {
    let session: Session

    var body: some View {
        VStack(spacing: 20) {
            Text("Sala: \(session.code)")
                .font(.title2.monospaced().bold())
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            List(session.participants) { participant in
                ParticipantRow(participant: participant)
            }

            Button("Iniciar Partida") {
                // TODO: Start session
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .navigationTitle("Lobby")
    }
}

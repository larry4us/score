//
//  ScoreboardView.swift
//  DominoScore
//

import SwiftUI

/// Live scoreboard for an active session.
struct ScoreboardView: View {
    let session: Session

    var body: some View {
        VStack(spacing: 16) {
            Text("Sala: \(session.code)")
                .font(.headline.monospaced())

            Text("Status: \(session.status.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // TODO: Exibir participantes e pontuações quando implementados
            ContentUnavailableView(
                "Em breve",
                systemImage: "list.number",
                description: Text("O placar será exibido aqui.")
            )
        }
        .navigationTitle("Placar")
    }
}

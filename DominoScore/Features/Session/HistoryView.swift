//
//  HistoryView.swift
//  DominoScore
//

import SwiftUI

/// Shows the score history for the current session.
struct HistoryView: View {
    let entries: [ScoreEntry]
    let participants: [Participant]

    var body: some View {
        List(entries) { entry in
            HStack {
                Text(participantName(for: entry.participantId))
                Spacer()
                Text("Rodada \(entry.round)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("+\(entry.points)")
                    .font(.body.monospacedDigit())
            }
        }
        .navigationTitle("Historico")
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Sem registros",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Os pontos aparecerão aqui conforme forem adicionados.")
                )
            }
        }
    }

    private func participantName(for id: String) -> String {
        participants.first(where: { $0.id == id })?.name ?? "—"
    }
}

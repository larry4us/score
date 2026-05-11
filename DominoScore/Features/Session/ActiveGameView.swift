//
//  ActiveGameView.swift
//  DominoScore
//

import SwiftUI

/// Grid of team score cards for the active game.
struct ActiveGameView: View {
    let teams: [Team]
    let scoreDeltas: [Int]
    let currentUserId: String
    let onScoreChange: (Int, Int) -> Void
    let onFinish: () -> Void

    private var columnCount: Int {
        teams.count <= 1 ? 1 : 2
    }

    var body: some View {
        VStack(spacing: 0) {
            scoreGrid
                .padding(6)
                .frame(maxHeight: .infinity)

            Button("Finalizar Partida", role: .destructive, action: onFinish)
                .font(.footnote)
                .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var scoreGrid: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row) { team in
                        TeamScoreCardView(
                            team: team,
                            scoreDeltas: scoreDeltas,
                            isEditable: team.containsOwner(uid: currentUserId)
                        ) { delta in
                            onScoreChange(team.colorIndex, delta)
                        }
                    }
                }
            }
        }
    }

    private var rows: [[Team]] {
        stride(from: 0, to: teams.count, by: columnCount).map { start in
            Array(teams[start..<min(start + columnCount, teams.count)])
        }
    }
}

#Preview {
    let teams = [
        Team(colorIndex: 0, participants: [
            Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: "me"),
            Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: "me")
        ]),
        Team(colorIndex: 1, participants: [
            Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "other"),
            Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "other")
        ])
    ]
    ActiveGameView(
        teams: teams,
        scoreDeltas: [5, 10, 50],
        currentUserId: "me",
        onScoreChange: { _, _ in },
        onFinish: {}
    )
}

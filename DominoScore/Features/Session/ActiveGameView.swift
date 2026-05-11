//
//  ActiveGameView.swift
//  DominoScore
//

import SwiftUI

/// Grid of score cards for the active game, with a finish button.
struct ActiveGameView: View {
    let participants: [Participant]
    let scoreDeltas: [Int]
    let onScoreChange: (String, Int) -> Void
    let onFinish: () -> Void

    private var columnCount: Int {
        participants.count <= 1 ? 1 : 2
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
    }

    private var scoreGrid: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row) { participant in
                        ScoreCardView(
                            participant: participant,
                            scoreDeltas: scoreDeltas
                        ) { delta in
                            onScoreChange(participant.id, delta)
                        }
                    }
                }
            }
        }
    }

    /// Split participants into rows of `columnCount`.
    private var rows: [[Participant]] {
        stride(from: 0, to: participants.count, by: columnCount).map { start in
            Array(participants[start..<min(start + columnCount, participants.count)])
        }
    }
}

#Preview {
    ActiveGameView(
        participants: Session.mock.participants,
        scoreDeltas: [5, 10, 50],
        onScoreChange: { _, _ in },
        onFinish: {}
    )
}

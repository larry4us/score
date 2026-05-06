//
//  ScoreboardView.swift
//  DominoScore
//

import SwiftUI

/// Live scoreboard for an active session.
struct ScoreboardView: View {
    let session: Session

    var body: some View {
        List {
            ForEach(session.participants.sorted(by: { $0.totalScore > $1.totalScore })) { participant in
                HStack {
                    Text(participant.name)
                        .font(.headline)
                    Spacer()
                    Text("\(participant.totalScore)")
                        .font(.title3.monospacedDigit().bold())
                }
            }
        }
        .navigationTitle("Placar")
    }
}

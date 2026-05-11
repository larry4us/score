//
//  FinishedGameView.swift
//  DominoScore
//

import SwiftUI

/// Final ranking shown when the game is over.
struct FinishedGameView: View {
    let participants: [Participant]

    private var ranked: [Participant] {
        participants.sorted { $0.totalScore > $1.totalScore }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text("Partida Encerrada")
                .font(.title2.bold())

            VStack(spacing: 12) {
                ForEach(ranked.enumerated(), id: \.element.id) { index, participant in
                    HStack {
                        Text("\(index + 1)º")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(index == 0 ? .yellow : .secondary)
                            .frame(width: 32)
                        Text(participant.name)
                        Spacer()
                        Text("\(participant.totalScore) pts")
                            .font(.headline.monospacedDigit())
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
    }
}

#Preview {
    FinishedGameView(participants: [
        Participant(name: "Pedro", totalScore: 200),
        Participant(name: "João", totalScore: 120),
        Participant(name: "Maria", totalScore: 85),
        Participant(name: "Ana", totalScore: 50)
    ])
}

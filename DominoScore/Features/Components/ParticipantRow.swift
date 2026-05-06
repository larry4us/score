//
//  ParticipantRow.swift
//  DominoScore
//

import SwiftUI

/// Reusable row displaying a participant's name and score.
struct ParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(participant.name)
                .font(.body)

            Spacer()

            Text("\(participant.totalScore) pts")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ParticipantRow(participant: Participant(name: "Jogador 1", totalScore: 42))
}

//
//  ScoreCardView.swift
//  DominoScore
//

import SwiftUI

/// A single player's score card with name, large score display, and inline +/- buttons.
/// Everything is one-tap — no selection step needed.
struct ScoreCardView: View {
    let participant: Participant
    let scoreDeltas: [Int]
    let onScoreChange: (Int) -> Void

    /// Triggers haptic feedback on score change.
    @State private var scoreTrigger = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(participant.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(participant.totalScore)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Botões de adicionar
            HStack(spacing: 6) {
                ForEach(scoreDeltas, id: \.self) { delta in
                    Button {
                        scoreTrigger += 1
                        onScoreChange(delta)
                    } label: {
                        Text("+\(delta)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            // Botões de remover
            HStack(spacing: 6) {
                ForEach(scoreDeltas, id: \.self) { delta in
                    Button {
                        scoreTrigger += 1
                        onScoreChange(-delta)
                    } label: {
                        Text("-\(delta)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: scoreTrigger)
    }
}

#Preview {
    ScoreCardView(
        participant: Participant(name: "João", totalScore: 120),
        scoreDeltas: [5, 10, 50],
        onScoreChange: { _ in }
    )
    .frame(width: 180, height: 240)
    .padding()
}

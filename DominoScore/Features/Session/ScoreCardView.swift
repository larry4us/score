//
//  ScoreCardView.swift
//  DominoScore
//

import SwiftUI

/// A team's score card with team color, member names, large score, and inline +/- buttons.
/// Buttons are disabled when the current user doesn't belong to this team.
struct TeamScoreCardView: View {
    let team: Team
    let scoreDeltas: [Int]
    let isEditable: Bool
    let onScoreChange: (Int) -> Void

    @State private var scoreTrigger = 0

    var body: some View {
        VStack(spacing: 8) {
            // Team header
            HStack(spacing: 6) {
                Circle()
                    .fill(team.color)
                    .frame(width: 12, height: 12)
                Text(Team.name(for: team.colorIndex))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Member names
            Text(team.memberNames)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)

            Spacer(minLength: 0)

            Text("\(team.totalScore)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Add buttons
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
                    .disabled(!isEditable)
                }
            }

            // Subtract buttons
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
                    .disabled(!isEditable)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(team.color.opacity(0.4), lineWidth: 2)
        )
        .opacity(isEditable ? 1.0 : 0.7)
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: scoreTrigger)
    }
}

#Preview {
    let team = Team(
        colorIndex: 0,
        participants: [
            Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: "uid"),
            Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: "uid")
        ]
    )
    TeamScoreCardView(
        team: team,
        scoreDeltas: [5, 10, 50],
        isEditable: true,
        onScoreChange: { _ in }
    )
    .frame(width: 180, height: 260)
    .padding()
}

//
//  FinishedGameView.swift
//  DominoScore
//

import SwiftUI

/// Final ranking shown when the game is over, ranked by team total score.
struct FinishedGameView: View {
    let teams: [Team]

    @Namespace private var rankNamespace

    private var ranked: [Team] {
        teams.sorted { $0.totalScore > $1.totalScore }
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

            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(ranked.enumerated(), id: \.element.id) { index, team in
                        HStack {
                            Text("\(index + 1)º")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(index == 0 ? .yellow : .secondary)
                                .frame(width: 32)
                            Circle()
                                .fill(team.color)
                                .frame(width: 16, height: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Team.name(for: team.colorIndex))
                                    .font(.body.weight(.medium))
                                Text(team.memberNames)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(team.totalScore) pts")
                                .font(.headline.monospacedDigit())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(
                            .regular.tint(team.color.opacity(0.15)),
                            in: .rect(cornerRadius: 12)
                        )
                        .glassEffectID(team.colorIndex, in: rankNamespace)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

#Preview {
    FinishedGameView(teams: [
        Team(colorIndex: 0, participants: [
            Participant(name: "João", totalScore: 120, teamColorIndex: 0),
            Participant(name: "Maria", totalScore: 85, teamColorIndex: 0)
        ]),
        Team(colorIndex: 1, participants: [
            Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1),
            Participant(name: "Ana", totalScore: 50, teamColorIndex: 1)
        ])
    ])
}

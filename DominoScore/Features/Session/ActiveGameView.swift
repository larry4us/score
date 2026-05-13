//
//  ActiveGameView.swift
//  DominoScore
//

import SwiftUI

/// Active game: all team scores displayed as a scoreboard on top,
/// own-team score buttons on the bottom. Remote changes trigger a flash + haptic.
struct ActiveGameView: View {
    let teams: [Team]
    let scoreButtons: [ScoreButton]
    let currentUserId: String
    let isOffline: Bool
    @Binding var selectedTeamColorIndex: Int?
    let onScoreChange: (Int, Int) -> Void

    /// Tracks the score snapshot to detect remote changes.
    @State private var previousScores: [Int: Int] = [:]
    /// Set of team colorIndexes currently flashing.
    @State private var flashingTeams: Set<Int> = []
    /// Trigger for remote-change haptic feedback.
    @State private var remoteChangeTrigger = 0
    /// Toggle between adding and subtracting points.
    @State private var isSubtracting = false

    @Namespace private var scoreNamespace

    private var myTeam: Team? {
        teams.first { $0.containsOwner(uid: currentUserId) }
    }

    /// The team whose score the buttons affect.
    private var activeTeam: Team? {
        if isOffline, let idx = selectedTeamColorIndex {
            return teams.first { $0.colorIndex == idx }
        }
        return myTeam
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Scoreboard (all teams)
            scoreboard
                .padding()
                .frame(maxHeight: .infinity)

            Divider()

            // MARK: - Own team controls
            ownTeamControls
                .padding()
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.6), trigger: remoteChangeTrigger)
        .onChange(of: teams) { oldTeams, newTeams in
            detectRemoteChanges(old: oldTeams, new: newTeams)
        }
        .onAppear {
            for team in teams {
                previousScores[team.colorIndex] = team.totalScore
            }
            if isOffline && selectedTeamColorIndex == nil {
                selectedTeamColorIndex = teams.first?.colorIndex
            }
        }
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 12) {
                ForEach(teams) { team in
                    scoreRow(for: team)
                }
            }
            
        }
    }

    private func scoreRow(for team: Team) -> some View {
        let isFlashing = flashingTeams.contains(team.colorIndex)
        let isMine = isOffline ? (selectedTeamColorIndex == team.colorIndex) : team.containsOwner(uid: currentUserId)
        let tintOpacity: Double = isMine ? 0.35 : 0.15

        return Button {
            guard isOffline else { return }
            selectedTeamColorIndex = team.colorIndex
        } label: {
            HStack(spacing: 12) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(team.color)
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Team.name(for: team.colorIndex))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(team.memberNames)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(team.totalScore)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(isMine ? team.color : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .contentShape(.rect)
        .glassEffect(
            .clear.tint(team.color.opacity(tintOpacity)).interactive(isMine),
            in: .rect(cornerRadius: 12)
        )
        .glassEffectID(team.colorIndex, in: scoreNamespace)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isMine ? team.color.opacity(0.4) : .clear, lineWidth: 2)
        )
        .opacity(isOffline && !isMine ? 0.6 : 1.0)
        .scaleEffect(isFlashing ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
        .sensoryFeedback(.selection, trigger: selectedTeamColorIndex)
    }

    // MARK: - Own Team Controls

    private var ownTeamControls: some View {
        VStack(spacing: 12) {
            if let activeTeam {
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(isSubtracting ? Color.secondary : Color.green)
                    Toggle("", isOn: $isSubtracting)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(.red)
                    Image(systemName: "minus")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(isSubtracting ? Color.red : Color.secondary)
                }
                .sensoryFeedback(.selection, trigger: isSubtracting)

                HStack(spacing: 10) {
                    ForEach(scoreButtons) { btn in
                        let sign = isSubtracting ? -1 : 1
                        Button {
                            onScoreChange(activeTeam.colorIndex, btn.value * sign)
                        } label: {
                            if btn.isGalo {
                                Text("🐓")
                                    .font(.title3.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("\(btn.value)")
                                    .font(.title3.weight(.bold).monospacedDigit())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .buttonStyle(.glass)
                        .tint(isSubtracting ? .red : .green)
                    }
                }
            } else {
                Text("Você não pertence a nenhum time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Remote Change Detection

    private func detectRemoteChanges(old: [Team], new: [Team]) {
        var changed: Set<Int> = []

        for team in new {
            let oldScore = previousScores[team.colorIndex]
            if let oldScore, oldScore != team.totalScore {
                changed.insert(team.colorIndex)
            }
            previousScores[team.colorIndex] = team.totalScore
        }

        guard !changed.isEmpty else { return }

        flashingTeams = changed
        remoteChangeTrigger += 1

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            flashingTeams = []
        }
    }
}

#Preview("Online") {
    @Previewable @State var selected: Int? = nil
    let teams = [
        Team(colorIndex: 0, participants: [
            Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: ""),
            Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: "")
        ]),
        Team(colorIndex: 1, participants: [
            Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "other"),
            Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "other")
        ])
    ]
    ActiveGameView(
        teams: teams,
        scoreButtons: ScoreButton.defaultButtons,
        currentUserId: "",
        isOffline: false,
        selectedTeamColorIndex: $selected,
        onScoreChange: { _, _ in }
    )
}
#Preview("Offline") {
    @Previewable @State var selected: Int? = 0
    let teams = [
        Team(colorIndex: 0, participants: [
            Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: "host"),
            Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: "host")
        ]),
        Team(colorIndex: 1, participants: [
            Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "host"),
            Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "host")
        ])
    ]
    ActiveGameView(
        teams: teams,
        scoreButtons: ScoreButton.defaultButtons,
        currentUserId: "host",
        isOffline: true,
        selectedTeamColorIndex: $selected,
        onScoreChange: { _, _ in }
    )
}


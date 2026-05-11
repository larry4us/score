//
//  WaitingView.swift
//  DominoScore
//

import SwiftUI

/// Waiting room shown before the game starts.
/// Each participant is shown as a colored card. Tapping your own card cycles the team color.
struct WaitingView: View {
    let session: Session
    let participants: [Participant]
    let currentUserId: String
    let isHost: Bool
    let onAddPlayer: () -> Void
    let onStart: () -> Void
    let onToggleTeamColor: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Session code
            VStack(spacing: 4) {
                Text("Código da Sala")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.code)
                    .font(.largeTitle.monospaced().bold())
                    .padding(8)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            }
            .padding(.top, 8)

            if participants.isEmpty {
                Spacer()
                Text("Adicione jogadores para começar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Text("Toque no seu card para mudar de time")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Player cards grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(participants) { p in
                        playerCard(for: p)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }

            // Actions
            VStack(spacing: 12) {
                Button("Adicionar Jogador", systemImage: "person.badge.plus", action: onAddPlayer)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(participants.count >= 4)

                if isHost {
                    Button("Iniciar Partida", action: onStart)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(participants.isEmpty)
                } else {
                    Text("Aguardando o host iniciar...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Player Card

    private func playerCard(for participant: Participant) -> some View {
        let isMine = participant.ownerUid == currentUserId
        let color = Team.color(for: participant.teamColorIndex)

        return Button {
            guard isMine else { return }
            onToggleTeamColor(participant.id)
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if participant.ownerUid == session.hostUid {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text(participant.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Text(Team.name(for: participant.teamColorIndex))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.gradient, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isMine ? 0.6 : 0), lineWidth: 2)
            )
            .opacity(isMine ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: participant.teamColorIndex)
    }
}

#Preview {
    WaitingView(
        session: .mock,
        participants: Session.mock.participants,
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onStart: {},
        onToggleTeamColor: { _ in }
    )
}

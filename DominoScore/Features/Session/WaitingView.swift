//
//  WaitingView.swift
//  DominoScore
//

import SwiftUI

/// Waiting room shown before the game starts.
/// Participant cards use Liquid Glass with team-colored tints.
/// Same-team cards fuse together via `glassEffectUnion`.
struct WaitingView: View {
    let session: Session
    let participants: [Participant]
    let currentUserId: String
    let isHost: Bool
    let onAddPlayer: () -> Void
    let onToggleTeamColor: (String) -> Void
    let onStart: () -> Void
    
    @Namespace private var glassNamespace
    @State private var showQRCode = false
    
    /// Teams sorted by color index, each containing up to 2 participants.
    private var teamGroups: [(colorIndex: Int, members: [Participant])] {
        let grouped = Dictionary(grouping: participants, by: \.teamColorIndex)
        return grouped.map { (colorIndex: $0.key, members: $0.value) }
            .sorted { $0.colorIndex < $1.colorIndex }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            sessionCodeHeader
            participantGrid
            actionButtons
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet(code: session.code)
                .presentationDetents([.fraction(0.7)])
        }
    }
}

// MARK: - Session Code Header

private struct SessionCodeHeader: View {
    let code: String
    let onShowQR: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Código da Sala")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Text(code)
                    .font(.largeTitle.monospaced().bold())
                Button(action: onShowQR) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mostrar QR Code")
            }
            .padding(8)
            .glassEffect(in: .rect(cornerRadius: 12))
        }
        .padding(.top, 8)
    }
}



// MARK: - Participant Card

private struct ParticipantCard: View {
    let participant: Participant
    let isHost: Bool
    let isMine: Bool
    let sessionHostUid: String
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if participant.ownerUid == sessionHostUid {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text(participant.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
                Text(Team.name(for: participant.teamColorIndex))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .opacity(isMine ? 1.0 : 0.7)
        .sensoryFeedback(.selection, trigger: participant.teamColorIndex)
        .accessibilityLabel("\(participant.name), \(Team.name(for: participant.teamColorIndex))")
        .accessibilityHint(isMine ? "Toque para mudar de time" : "")
    }
    
    private func handleTap() {
        guard isMine else { return }
        onToggle()
    }
}

// MARK: - Private Subviews

private extension WaitingView {
    var sessionCodeHeader: some View {
        SessionCodeHeader(code: session.code, onShowQR: { showQRCode = true })
    }
    
    @ViewBuilder
    var participantGrid: some View {
        if participants.isEmpty {
            ContentUnavailableView(
                "Nenhum jogador",
                systemImage: "person.slash",
                description: Text("Adicione jogadores para começar")
            )
        } else {
            Text("Toque no seu card para mudar de time")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GlassEffectContainer(spacing: 12) {
                VStack(alignment: .center, spacing: 12) {
                    ForEach(teamGroups, id: \.colorIndex) { group in
                        HStack(spacing: 12) {
                            ForEach(group.members) { participant in
                                let isMine = participant.ownerUid == currentUserId
                                let teamColor = Team.color(for: participant.teamColorIndex)
                                
                                ParticipantCard(
                                    participant: participant,
                                    isHost: isHost,
                                    isMine: isMine,
                                    sessionHostUid: session.hostUid,
                                    onToggle: {
                                        withAnimation {
                                            onToggleTeamColor(participant.id)
                                        }
                                    }
                                )
                                .glassEffect(
                                    .regular.tint(teamColor.opacity(0.3)).interactive(isMine),
                                    in: .rect(cornerRadius: 16)
                                )
                                .glassEffectID(participant.id, in: glassNamespace)
                                .glassEffectUnion(
                                    id: participant.teamColorIndex,
                                    namespace: glassNamespace
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Adicionar Jogador", systemImage: "person.badge.plus", action: onAddPlayer)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .disabled(participants.count >= 4)

                if isHost {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                            .font(.body)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .tint(.green)
                    .disabled(participants.isEmpty)
                    .accessibilityLabel("Iniciar partida")
                }
            }
            
            if !isHost {
                Text("Aguardando o host iniciar...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Previews

#Preview("Host — 4 players, 2 teams") {
    //@Previewable @State var showQR = true
    
    WaitingView(
        session: .mock,
        participants: Participant.mockList,
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onToggleTeamColor: { _ in },
        onStart: {}
    )
//    .sheet(isPresented: $showQR) {
//        QRCodeSheet(code: Session.mock.code)
//            .presentationDetents([.fraction(0.65)])
//            
//    }
//     
        
}

#Preview("Joiner — waiting") {
    WaitingView(
        session: .mock,
        participants: Participant.mockList,
        currentUserId: "joiner-1",
        isHost: false,
        onAddPlayer: {},
        onToggleTeamColor: { _ in },
        onStart: {}
    )
}

#Preview("Empty room") {
    WaitingView(
        session: .mock,
        participants: [],
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onToggleTeamColor: { _ in },
        onStart: {}
    )
}

#Preview("All same team") {
    let allRed = [
        Participant(name: "João", teamColorIndex: 0, ownerUid: "mock-uid"),
        Participant(name: "Maria", teamColorIndex: 0, ownerUid: "joiner-1"),
        Participant(name: "Pedro", teamColorIndex: 0, ownerUid: "joiner-2"),
        Participant(name: "Ana", teamColorIndex: 0, ownerUid: "joiner-3"),
    ]
    WaitingView(
        session: .mock,
        participants: allRed,
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onToggleTeamColor: { _ in },
        onStart: {}
    )
}

#Preview("3 teams") {
    let threeTeams = [
        Participant(name: "João", teamColorIndex: 0, ownerUid: "mock-uid"),
        Participant(name: "Maria", teamColorIndex: 1, ownerUid: "joiner-1"),
        Participant(name: "Pedro", teamColorIndex: 2, ownerUid: "joiner-2"),
        Participant(name: "Ana", teamColorIndex: 1, ownerUid: "joiner-3"),
    ]
    WaitingView(
        session: .mock,
        participants: threeTeams,
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onToggleTeamColor: { _ in },
        onStart: {}
    )
}


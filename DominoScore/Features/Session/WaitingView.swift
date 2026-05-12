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
    let onStart: () -> Void
    let onToggleTeamColor: (String) -> Void
    
    @Namespace private var glassNamespace
    @State private var showQRCode = false
    
    /// Participants sorted by team so same-team members are always adjacent.
    private var sortedParticipants: [Participant] {
        participants.sorted { $0.teamColorIndex < $1.teamColorIndex }
    }
    
    /// Splits sorted participants into rows of 2 for a clean grid.
    private var rows: [[Participant]] {
        stride(from: 0, to: sortedParticipants.count, by: 2).map { index in
            Array(sortedParticipants[index..<min(index + 2, sortedParticipants.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            sessionCodeHeader
            participantGrid
            actionButtons
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet(code: session.code)
                .presentationDetents([.fraction(0.6)])
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

// MARK: - QR Code Sheet

private struct QRCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    private let qrService = QRCodeService()
    
    var body: some View {
        
        VStack(spacing: 24) {
            Spacer()
            
            Text("Compartilhar Sala")
                .font(.title2.bold())
            
            Text("Peça para escanearem este código para entrar na sala")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let uiImage = qrService.generateQRCode(from: code) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(16)
                    .glassEffect(in: .rect(cornerRadius: 20))
            }
            
            Text(code)
                .font(.title3.monospaced().bold())
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fechar") { dismiss() }
            }
        }
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
            .frame(maxWidth: .infinity)
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
                VStack(spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 12) {
                            ForEach(row) { participant in
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
                                    .regular.tint(teamColor.opacity(0.2)).interactive(isMine),
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
            Button("Adicionar Jogador", systemImage: "person.badge.plus", action: onAddPlayer)
                .frame(maxWidth: .infinity)
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(participants.count >= 4)
            
            if isHost {
                Button("Iniciar Partida", action: onStart)
                    .buttonStyle(.glassProminent)
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

// MARK: - Previews

#Preview("Host — 4 players, 2 teams") {
    WaitingView(
        session: .mock,
        participants: Participant.mockList,
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onStart: {},
        onToggleTeamColor: { _ in }
    )
}

#Preview("Joiner — waiting") {
    WaitingView(
        session: .mock,
        participants: Participant.mockList,
        currentUserId: "joiner-1",
        isHost: false,
        onAddPlayer: {},
        onStart: {},
        onToggleTeamColor: { _ in }
    )
}

#Preview("Empty room") {
    WaitingView(
        session: .mock,
        participants: [],
        currentUserId: "mock-uid",
        isHost: true,
        onAddPlayer: {},
        onStart: {},
        onToggleTeamColor: { _ in }
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
        onStart: {},
        onToggleTeamColor: { _ in }
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
        onStart: {},
        onToggleTeamColor: { _ in }
    )
}


//
//  LobbyView.swift
//  DominoScore
//

import SwiftUI

/// Lobby / placar ao vivo. Coordena as subviews por status da sessão.
struct LobbyView: View {
    @Environment(Coordinator.self) private var coordinator
    let session: Session

    @State private var showAddPlayer = false
    @State private var newPlayerName = ""
    @State private var localParticipants: [Participant] = []

    private var repo: SessionRepository { coordinator.sessionRepository }
    private var liveSession: Session { repo.currentSession ?? session }
    private var currentUserId: String { coordinator.authService?.currentUserId ?? "" }

    /// Valores fixos dos botões (preparado para personalização futura).
    private let scoreDeltas = [5, 10, 50]

    /// Groups live participants into teams (used for active/finished phases).
    private var teams: [Team] {
        let grouped = Dictionary(grouping: liveSession.participants, by: \.teamColorIndex)
        return grouped.map { Team(colorIndex: $0.key, participants: $0.value) }
            .sorted { $0.colorIndex < $1.colorIndex }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch liveSession.status {
            case .waiting:
                WaitingView(
                    session: liveSession,
                    participants: localParticipants,
                    onAddPlayer: { showAddPlayer = true },
                    onStart: { Task { await startGame() } },
                    onToggleTeamColor: { toggleTeamColor(for: $0) }
                )
            case .active:
                ActiveGameView(
                    teams: teams,
                    scoreDeltas: scoreDeltas,
                    currentUserId: currentUserId,
                    onScoreChange: { colorIndex, delta in handleTeamScoreChange(teamColorIndex: colorIndex, delta: delta) },
                    onFinish: { Task { await updateStatus(.finished) } }
                )
            case .finished:
                FinishedGameView(teams: teams)
            }
        }
        .navigationTitle(liveSession.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Label(statusLabel, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .labelStyle(.titleAndIcon)
            }
        }
        .alert("Adicionar Jogador", isPresented: $showAddPlayer) {
            TextField("Nome do jogador", text: $newPlayerName)
            Button("Adicionar", action: handleAddPlayer)
            Button("Cancelar", role: .cancel) { newPlayerName = "" }
        }
    }

    // MARK: - Actions (offline setup)

    private func handleAddPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        localParticipants.append(
            Participant(name: name, ownerUid: currentUserId)
        )
        newPlayerName = ""
    }

    private func toggleTeamColor(for participantId: String) {
        guard let index = localParticipants.firstIndex(where: { $0.id == participantId }) else { return }
        localParticipants[index].teamColorIndex =
            (localParticipants[index].teamColorIndex + 1) % Team.availableColors
    }

    private func startGame() async {
        guard !localParticipants.isEmpty else { return }
        await repo.startGame(participants: localParticipants)
    }

    // MARK: - Actions (active game)

    private func handleTeamScoreChange(teamColorIndex: Int, delta: Int) {
        Task { await repo.updateTeamScore(teamColorIndex: teamColorIndex, delta: delta) }
    }

    private func updateStatus(_ status: Session.Status) async {
        guard let id = liveSession.id else { return }
        await repo.updateStatus(status, sessionId: id)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch liveSession.status {
        case .waiting:  .orange
        case .active:   .green
        case .finished: .gray
        }
    }

    private var statusLabel: String {
        switch liveSession.status {
        case .waiting:  "Aguardando"
        case .active:   "Em andamento"
        case .finished: "Finalizada"
        }
    }
}

#Preview {
    NavigationStack {
        LobbyView(session: Session(
            code: "AB3K7",
            hostUid: "mock",
            status: .active,
            participants: [
                Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: "mock"),
                Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: "mock"),
                Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "other"),
                Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "other")
            ]
        ))
        .environment(Coordinator(authenticated: true))
    }
}

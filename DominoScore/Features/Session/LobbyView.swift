//
//  LobbyView.swift
//  DominoScore
//

import SwiftUI

/// Lobby / placar ao vivo. Coordena as subviews por status da sessão.
/// Distinguishes host (offline setup) from joiners (write to Firestore immediately).
struct LobbyView: View {
    @Environment(Coordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    let session: Session

    @State private var showAddPlayer = false
    @State private var newPlayerName = ""
    @State private var hasJoined = false
    @State private var showLeaveConfirmation = false
    @State private var showScoreConfig = false
    @State private var selectedTeamColorIndex: Int?
    @AppStorage("scoreButtons") private var scoreButtonsJSON = ScoreButton.defaultButtons.jsonString

    private var repo: SessionRepository { coordinator.sessionRepository }
    private var liveSession: Session { repo.currentSession ?? session }
    private var currentUserId: String { coordinator.authService?.currentUserId ?? "" }
    private var currentFirstName: String {
        let full = coordinator.authService?.displayName ?? ""
        return full.components(separatedBy: " ").first ?? full
    }
    private var isHost: Bool { liveSession.hostUid == currentUserId }
    private var isOffline: Bool { liveSession.mode == .offline }

    private var scoreButtons: [ScoreButton] {
        [ScoreButton](jsonString: scoreButtonsJSON)
    }

    private var scoreButtonsBinding: Binding<[ScoreButton]> {
        Binding(
            get: { scoreButtons },
            set: { scoreButtonsJSON = $0.jsonString }
        )
    }

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
                    participants: liveSession.participants,
                    currentUserId: currentUserId,
                    isHost: isHost,
                    onAddPlayer: { showAddPlayer = true },
                    onToggleTeamColor: { handleToggleTeamColor(for: $0) },
                    onStart: { Task { await startGame() } },
                    isOffline: isOffline
                )
            case .active:
                ActiveGameView(
                    teams: teams,
                    scoreButtons: scoreButtons,
                    currentUserId: currentUserId,
                    isOffline: isOffline,
                    selectedTeamColorIndex: $selectedTeamColorIndex,
                    onScoreChange: { colorIndex, delta in handleTeamScoreChange(teamColorIndex: colorIndex, delta: delta) }
                )
            case .finished:
                FinishedGameView(teams: teams)
            }
        }
        .navigationTitle(activeNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showLeaveConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            if isOffline && liveSession.status == .active, let idx = selectedTeamColorIndex {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Team.color(for: idx))
                            .frame(width: 10, height: 10)
                        Text("Time \(Team.name(for: idx))")
                            .font(.headline)
                    }
                }
            }
            if isHost && liveSession.status == .waiting {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScoreConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Configurar botões de pontuação")
                }
            }
        }
        .alert("Adicionar Jogador", isPresented: $showAddPlayer) {
            TextField("Nome do jogador", text: $newPlayerName)
            Button("Adicionar", action: handleAddPlayer)
            Button("Cancelar", role: .cancel) { newPlayerName = "" }
        }
        .alert(leaveAlertTitle, isPresented: $showLeaveConfirmation) {
            Button("Sair", role: .destructive) {
                Task { await leaveSession() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(leaveAlertMessage)
        }
        .sheet(isPresented: $showScoreConfig) {
            ScoreButtonsConfigSheet(buttons: scoreButtonsBinding)
        }
        .onAppear {
            guard !hasJoined else { return }
            hasJoined = true

            // Joiner: add self as participant if not already present (online only)
            if !isOffline && !isHost {
                let alreadyJoined = liveSession.participants.contains { $0.id == currentUserId }
                if !alreadyJoined {
                    let participant = Participant(id: currentUserId, name: currentFirstName, ownerUid: currentUserId)
                    Task { await repo.addParticipant(participant) }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Actions (waiting)

    private func handleAddPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let participant = Participant(name: name, ownerUid: currentUserId)
        if isOffline {
            repo.addOfflineParticipant(participant)
        } else {
            Task { await repo.addParticipant(participant) }
        }
        newPlayerName = ""
    }

    private func handleToggleTeamColor(for participantId: String) {
        guard let participant = liveSession.participants.first(where: { $0.id == participantId }) else { return }

        // In online mode, only allow toggling own cards
        if !isOffline && participant.ownerUid != currentUserId { return }

        // Count members per team, excluding the current participant
        let others = liveSession.participants.filter { $0.id != participantId }
        let teamCounts = Dictionary(grouping: others, by: \.teamColorIndex)
            .mapValues(\.count)

        // Find next color that isn't full
        let total = Team.availableColors
        var candidate = (participant.teamColorIndex + 1) % total
        for _ in 0..<total {
            let count = teamCounts[candidate] ?? 0
            if count < Team.maxPerTeam {
                break
            }
            candidate = (candidate + 1) % total
        }

        guard candidate != participant.teamColorIndex else { return }
        if isOffline {
            repo.updateOfflineParticipantTeamColor(participantId: participantId, teamColorIndex: candidate)
        } else {
            Task { await repo.updateParticipantTeamColor(participantId: participantId, teamColorIndex: candidate) }
        }
    }

    private func startGame() async {
        guard isHost, !liveSession.participants.isEmpty else { return }
        if isOffline {
            repo.startOfflineGame(participants: liveSession.participants)
        } else {
            await repo.startGame(participants: liveSession.participants)
        }
    }

    // MARK: - Actions (active game)

    private func handleTeamScoreChange(teamColorIndex: Int, delta: Int) {
        if isOffline {
            repo.updateOfflineTeamScore(teamColorIndex: teamColorIndex, delta: delta)
        } else {
            Task { await repo.updateTeamScore(teamColorIndex: teamColorIndex, delta: delta) }
        }
    }

    private func updateStatus(_ status: Session.Status) async {
        guard let id = liveSession.id else { return }
        await repo.updateStatus(status, sessionId: id)
    }

    // MARK: - Leave

    private func leaveSession() async {
        if isOffline {
            repo.finishOfflineGame()
        } else {
            if isHost && liveSession.status == .active {
                await updateStatus(.finished)
            }
            repo.stopListening()
        }
        dismiss()
    }

    private var leaveAlertTitle: String {
        liveSession.status == .active ? "Finalizar Partida" : "Sair da Sala"
    }

    private var leaveAlertMessage: String {
        if isHost && liveSession.status == .active {
            return "A partida será finalizada para todos. Deseja continuar?"
        }
        return "Tem certeza que deseja sair?"
    }

    // MARK: - Helpers

    private var myTeam: Team? {
        teams.first { $0.containsOwner(uid: currentUserId) }
    }

    private var activeNavigationTitle: String {
        switch liveSession.status {
        case .active:
            if isOffline, let idx = selectedTeamColorIndex {
                "Time \(Team.name(for: idx))"
            } else if let myTeam {
                "Time \(Team.name(for: myTeam.colorIndex))"
            } else {
                liveSession.displayName
            }
        case .waiting:
            "Escolha dos times"
        case .finished:
            liveSession.displayName
        }
    }

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

#Preview("Active — Host") {
    NavigationStack {
        LobbyView(session: Session(
            code: "AB3K7",
            hostUid: "",
            status: .active,
            participants: [
                Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: ""),
                Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: ""),
                Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "other"),
                Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "other")
            ]
        ))
        .environment(Coordinator(authenticated: true))
    }
}

#Preview("Waiting — Host") {
    NavigationStack {
        LobbyView(session: Session(
            code: "AB3K7",
            hostUid: "",
            status: .waiting,
            participants: [
                Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: ""),
                Participant(name: "Maria", totalScore: 85, teamColorIndex: 0, ownerUid: ""),
                Participant(name: "Pedro", totalScore: 200, teamColorIndex: 1, ownerUid: "other"),
                Participant(name: "Ana", totalScore: 50, teamColorIndex: 1, ownerUid: "other")
            ]
        ))
        .environment(Coordinator(authenticated: true))
    }
}

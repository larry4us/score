//
//  SessionRepository.swift
//  DominoScore
//

import Foundation

/// Repositório que gerencia operações de sessão via Firestore.
/// Usa `@Observable` para publicar a sessão em tempo real.
@Observable
final class SessionRepository {

    private let client: FirestoreClient
    private let codeGenerator: CodeGenerator

    /// Sessão atual sendo observada em tempo real.
    private(set) var currentSession: Session?

    /// Mensagem de erro da última operação.
    private(set) var errorMessage: String?

    init(
        client: FirestoreClient = FirestoreClient(),
        codeGenerator: CodeGenerator = CodeGenerator()
    ) {
        self.client = client
        self.codeGenerator = codeGenerator
    }

    // MARK: - Create

    /// Cria uma nova sessão com código aleatório de 5 caracteres e status `waiting`.
    /// Includes the host as the initial participant.
    func createSession(hostUid: String, initialParticipant: Participant? = nil) async {
        let session = Session(
            code: codeGenerator.generate(),
            hostUid: hostUid,
            status: .waiting,
            participants: initialParticipant.map { [$0] } ?? []
        )

        do {
            let docId = try await client.createSession(session)
            listenToSession(sessionId: docId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Find

    /// Busca uma sessão pelo campo `code` e começa a escutar mudanças.
    func findSession(byCode code: String) async {
        do {
            guard let session = try await client.fetchSession(byCode: code),
                  let id = session.id else {
                errorMessage = "Sessão não encontrada."
                return
            }
            listenToSession(sessionId: id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Listen

    /// Abre um snapshot listener em tempo real que publica a sessão em `currentSession`.
    func listenToSession(sessionId: String) {
        client.listenToSession(id: sessionId) { [weak self] session in
            self?.currentSession = session
        }
    }

    // MARK: - Update

    /// Atualiza o campo `status` da sessão.
    func updateStatus(_ status: Session.Status, sessionId: String) async {
        do {
            try await client.updateStatus(status, sessionId: sessionId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Participants

    /// Adds a participant to the live session in Firestore (used by joiners).
    func addParticipant(_ participant: Participant) async {
        guard let session = currentSession, let id = session.id else { return }
        var updated = session.participants
        updated.append(participant)
        do {
            try await client.updateParticipants(updated, sessionId: id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates the team color of a participant in the live session.
    func updateParticipantTeamColor(participantId: String, teamColorIndex: Int) async {
        guard let session = currentSession, let id = session.id else { return }
        var updated = session.participants
        guard let index = updated.firstIndex(where: { $0.id == participantId }) else { return }
        updated[index].teamColorIndex = teamColorIndex
        do {
            try await client.updateParticipants(updated, sessionId: id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Start Game

    /// Writes participants and transitions to active atomically.
    /// Called once when the host taps "Iniciar Partida".
    func startGame(participants: [Participant]) async {
        guard let session = currentSession, let id = session.id else { return }
        do {
            try await client.startGame(participants: participants, sessionId: id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Team Score

    /// Updates score for a team by applying the delta to the first participant of that team.
    func updateTeamScore(teamColorIndex: Int, delta: Int) async {
        guard let session = currentSession, let id = session.id else { return }
        var updated = session.participants
        guard let index = updated.firstIndex(where: { $0.teamColorIndex == teamColorIndex }) else { return }
        updated[index].totalScore += delta
        do {
            try await client.updateParticipants(updated, sessionId: id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cleanup

    /// Remove o listener ativo.
    func stopListening() {
        client.removeListener()
        currentSession = nil
    }
}

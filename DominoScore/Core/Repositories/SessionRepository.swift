//
//  SessionRepository.swift
//  DominoScore
//

import Foundation

/// Protocol defining session data operations.
protocol SessionRepository {
    func create(_ session: Session) async throws
    func fetch(byCode code: String) async throws -> Session?
    func fetch(byId id: String) async throws -> Session?
    func update(_ session: Session) async throws
    func addScoreEntry(_ entry: ScoreEntry, toSession sessionId: String) async throws
    func listen(sessionId: String, onChange: @escaping (Session) -> Void)
}

/// Firestore-backed implementation of SessionRepository.
final class FirestoreSessionRepository: SessionRepository {

    private let client: FirestoreClient

    init(client: FirestoreClient = FirestoreClient()) {
        self.client = client
    }

    func create(_ session: Session) async throws {
        try await client.createSession(session)
    }

    func fetch(byCode code: String) async throws -> Session? {
        try await client.fetchSession(byCode: code)
    }

    func fetch(byId id: String) async throws -> Session? {
        // TODO: Implement fetch by ID
        return nil
    }

    func update(_ session: Session) async throws {
        try await client.updateSession(session)
    }

    func addScoreEntry(_ entry: ScoreEntry, toSession sessionId: String) async throws {
        try await client.addScoreEntry(entry, toSession: sessionId)
    }

    func listen(sessionId: String, onChange: @escaping (Session) -> Void) {
        client.listenToSession(id: sessionId, onChange: onChange)
    }
}

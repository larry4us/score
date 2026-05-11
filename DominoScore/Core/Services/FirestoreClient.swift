//
//  FirestoreClient.swift
//  DominoScore
//

import Foundation
import FirebaseFirestore

/// Thin wrapper around Firestore SDK for session data.
final class FirestoreClient {

    private let db = Firestore.firestore()
    private let sessionsCollection = "sessions"
    private let usersCollection = "users"

    private var listener: ListenerRegistration?

    // MARK: - Create

    /// Cria um novo documento na coleção `sessions`.
    /// O Firestore gera o ID automaticamente.
    @discardableResult
    func createSession(_ session: Session) async throws -> String {
        let ref = try db.collection(sessionsCollection).addDocument(from: session)
        return ref.documentID
    }

    // MARK: - Read

    /// Busca uma sessão pelo campo `code`.
    func fetchSession(byCode code: String) async throws -> Session? {
        let snapshot = try await db.collection(sessionsCollection)
            .whereField("code", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: Session.self)
    }

    // MARK: - Update

    /// Atualiza o campo `status` de uma sessão.
    func updateStatus(_ status: Session.Status, sessionId: String) async throws {
        try await db.collection(sessionsCollection)
            .document(sessionId)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Start Game

    /// Writes participants and sets status to `.active` atomically in a single Firestore write.
    func startGame(participants: [Participant], sessionId: String) async throws {
        let encoded = try participants.map { try Firestore.Encoder().encode($0) }
        try await db.collection(sessionsCollection)
            .document(sessionId)
            .updateData([
                "participants": encoded,
                "status": Session.Status.active.rawValue
            ])
    }

    // MARK: - Participants

    /// Atualiza o array `participants` inteiro no documento da sessão.
    func updateParticipants(_ participants: [Participant], sessionId: String) async throws {
        let encoded = try participants.map { try Firestore.Encoder().encode($0) }
        try await db.collection(sessionsCollection)
            .document(sessionId)
            .updateData(["participants": encoded])
    }

    // MARK: - Listener

    /// Abre um snapshot listener em tempo real para um documento de sessão.
    /// Retorna um `ListenerRegistration` para cancelar depois.
    @discardableResult
    func listenToSession(
        id: String,
        onChange: @escaping (Session?) -> Void
    ) -> ListenerRegistration {
        let registration = db.collection(sessionsCollection)
            .document(id)
            .addSnapshotListener { snapshot, error in
                guard let snapshot, snapshot.exists else {
                    onChange(nil)
                    return
                }
                let session = try? snapshot.data(as: Session.self)
                onChange(session)
            }
        self.listener = registration
        return registration
    }

    /// Remove o listener ativo, se houver.
    func removeListener() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Users

    /// Creates or overwrites a user document using the Auth uid as document ID.
    func upsertUser(_ user: AppUser, uid: String) async throws {
        try db.collection(usersCollection)
            .document(uid)
            .setData(from: user, merge: true)
    }

    /// Fetches a user document by uid.
    func fetchUser(uid: String) async throws -> AppUser? {
        let snapshot = try await db.collection(usersCollection)
            .document(uid)
            .getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: AppUser.self)
    }

    /// Updates the displayName field, creating the document if it doesn't exist.
    func updateUserDisplayName(_ name: String, uid: String) async throws {
        try await db.collection(usersCollection)
            .document(uid)
            .setData(["displayName": name], merge: true)
    }

    deinit {
        removeListener()
    }
}

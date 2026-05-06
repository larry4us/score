//
//  FirestoreClient.swift
//  DominoScore
//

import Foundation
import FirebaseFirestore

/// Thin wrapper around Firestore SDK for session data.
final class FirestoreClient {

    private let db = Firestore.firestore()
    private let collection = "sessions"

    private var listener: ListenerRegistration?

    // MARK: - Create

    /// Cria um novo documento na coleção `sessions`.
    /// O Firestore gera o ID automaticamente.
    @discardableResult
    func createSession(_ session: Session) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: session)
        return ref.documentID
    }

    // MARK: - Read

    /// Busca uma sessão pelo campo `code`.
    func fetchSession(byCode code: String) async throws -> Session? {
        let snapshot = try await db.collection(collection)
            .whereField("code", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: Session.self)
    }

    // MARK: - Update

    /// Atualiza o campo `status` de uma sessão.
    func updateStatus(_ status: Session.Status, sessionId: String) async throws {
        try await db.collection(collection)
            .document(sessionId)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Listener

    /// Abre um snapshot listener em tempo real para um documento de sessão.
    /// Retorna um `ListenerRegistration` para cancelar depois.
    @discardableResult
    func listenToSession(
        id: String,
        onChange: @escaping (Session?) -> Void
    ) -> ListenerRegistration {
        let registration = db.collection(collection)
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

    deinit {
        removeListener()
    }
}

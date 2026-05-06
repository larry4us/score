//
//  FirestoreClient.swift
//  DominoScore
//

import Foundation

/// Thin wrapper around Firestore SDK for session data.
final class FirestoreClient {

    // TODO: Add FirebaseFirestore import and configure

    func createSession(_ session: Session) async throws {
        // TODO: Write session document to Firestore
    }

    func fetchSession(byCode code: String) async throws -> Session? {
        // TODO: Query Firestore for session with matching code
        return nil
    }

    func updateSession(_ session: Session) async throws {
        // TODO: Update session document in Firestore
    }

    func listenToSession(id: String, onChange: @escaping (Session) -> Void) {
        // TODO: Attach Firestore snapshot listener
    }

    func addScoreEntry(_ entry: ScoreEntry, toSession sessionId: String) async throws {
        // TODO: Add score entry sub-document
    }
}

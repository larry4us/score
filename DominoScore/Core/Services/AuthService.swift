//
//  AuthService.swift
//  DominoScore
//

import Foundation
import FirebaseAuth

/// Handles user authentication via Firebase Auth.
@Observable
final class AuthService: Hashable {
    static func == (lhs: AuthService, rhs: AuthService) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    private(set) var currentUserId: String?
    private(set) var displayName: String?

    var isAuthenticated: Bool { currentUserId != nil }

    /// Restores a previous Firebase Auth session.
    /// Call this **after** `FirebaseApp.configure()` has completed.
    func restoreSession() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
            displayName = user.displayName
        }
    }

    // MARK: - Email & Password

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUserId = result.user.uid
        displayName = result.user.displayName
    }

    func createAccount(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        currentUserId = result.user.uid
        displayName = name
    }

    // MARK: - Session

    func signOut() {
        try? Auth.auth().signOut()
        currentUserId = nil
        displayName = nil
    }
}

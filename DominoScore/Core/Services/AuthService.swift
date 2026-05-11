//
//  AuthService.swift
//  DominoScore
//

import Foundation
import FirebaseAuth

/// Handles user authentication via Firebase Auth and syncs profile to Firestore.
@Observable
final class AuthService: Hashable {
    static func == (lhs: AuthService, rhs: AuthService) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    private let firestoreClient: FirestoreClient

    private(set) var currentUserId: String?
    private(set) var displayName: String?

    init(firestoreClient: FirestoreClient = FirestoreClient()) {
        self.firestoreClient = firestoreClient
    }

    var isAuthenticated: Bool { currentUserId != nil }

    /// Restores a previous Firebase Auth session.
    /// Call this **after** `FirebaseApp.configure()` has completed.
    ///
    /// On first launch after a fresh install, Firebase Auth may still have a
    /// cached user in the Keychain (which survives app deletion on iOS).
    /// We use a UserDefaults flag to detect first launch and sign out in that case.
    func restoreSession() {
        let hasLaunchedKey = "hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
            try? Auth.auth().signOut()
            return
        }

        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
            displayName = user.displayName
            // Load latest displayName from Firestore
            Task {
                if let appUser = try? await firestoreClient.fetchUser(uid: user.uid) {
                    displayName = appUser.displayName
                }
            }
        }
    }

    // MARK: - Email & Password

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let uid = result.user.uid
        currentUserId = uid

        // Load displayName from Firestore (source of truth), fallback to Auth
        if let appUser = try? await firestoreClient.fetchUser(uid: uid) {
            displayName = appUser.displayName
        } else {
            // First sign-in after migration — create Firestore user doc
            let name = result.user.displayName ?? ""
            displayName = name
            let appUser = AppUser(id: uid, displayName: name)
            try? await firestoreClient.upsertUser(appUser, uid: uid)
        }
    }

    func createAccount(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        currentUserId = result.user.uid
        displayName = name

        let appUser = AppUser(id: result.user.uid, displayName: name)
        try await firestoreClient.upsertUser(appUser, uid: result.user.uid)
    }

    // MARK: - Profile

    func updateDisplayName(_ name: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        displayName = name
        try await firestoreClient.updateUserDisplayName(name, uid: user.uid)
    }

    // MARK: - Session

    func signOut() {
        try? Auth.auth().signOut()
        currentUserId = nil
        displayName = nil
    }
}

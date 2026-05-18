//
//  AuthService.swift
//  DominoScore
//

import Foundation
import FirebaseAuth
import CryptoKit
import AuthenticationServices

/// Handles user authentication via Firebase Auth and syncs profile to Firestore.
@Observable
final class AuthService: NSObject {

    private let firestoreClient: FirestoreClient
    private(set) var currentUserId: String?
    private(set) var displayName: String?

    /// Continuation used to bridge the Apple Sign-In delegate callbacks into async/await.
    private var appleSignInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    /// Unhashed nonce for the current Apple Sign-In flow.
    private var currentNonce: String?

    init(firestoreClient: FirestoreClient = FirestoreClient()) {
        self.firestoreClient = firestoreClient
    }

    var isAuthenticated: Bool { currentUserId != nil }

    // MARK: - Restore Session

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
            Task {
                if let appUser = try? await firestoreClient.fetchUser(uid: user.uid) {
                    displayName = appUser.displayName
                }
            }
        }
    }

    // MARK: - Apple Sign-In

    /// Performs the full Sign in with Apple → Firebase Auth flow.
    func signInWithApple() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleCredential = try await requestAppleCredential(nonce: nonce)

        guard let appleIDToken = appleCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: firebaseCredential)
        let uid = result.user.uid
        currentUserId = uid

        // Build display name from Apple's fullName (only provided on first sign-in)
        let appleName = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        if let appUser = try? await firestoreClient.fetchUser(uid: uid) {
            displayName = appUser.displayName
        } else {
            let name = appleName.isEmpty ? (result.user.displayName ?? "") : appleName
            displayName = name
            let appUser = AppUser(id: uid, displayName: name)
            try? await firestoreClient.upsertUser(appUser, uid: uid)

            if !name.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try? await changeRequest.commitChanges()
            }
        }
    }

    /// Presents the Apple Sign-In sheet and returns the credential via a continuation.
    private func requestAppleCredential(nonce: String) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Email & Password

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let uid = result.user.uid
        currentUserId = uid

        if let appUser = try? await firestoreClient.fetchUser(uid: uid) {
            displayName = appUser.displayName
        } else {
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

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        currentUserId = nil
        displayName = nil
    }
}

// MARK: - Crypto Helpers

private extension AuthService {

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        appleSignInContinuation?.resume(returning: credential)
        appleSignInContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}
// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        return scene.windows.first ?? UIWindow(windowScene: scene)
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:
            return "Não foi possível obter o token de identidade da Apple."
        }
    }
}


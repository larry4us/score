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
    static func == (lhs: AuthService, rhs: AuthService) -> Bool {
        lhs === rhs
    }
    
    private let firestoreClient: FirestoreClient
    private(set) var currentUserId: String?
    private(set) var displayName: String?
    
    //Apple flow
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
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
    
    func signInWithApple() async throws {
        
    }
    
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
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

extension AuthService{
    
    /// Generates a random "nonce" wich is basically a cryptographed data
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

@available(iOS 13.0, *)
extension AuthService: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                }
                // User is signed in to Firebase with Apple.
                // ...
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}

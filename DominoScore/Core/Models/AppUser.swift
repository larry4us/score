//
//  AppUser.swift
//  DominoScore
//

import Foundation
import FirebaseFirestore

/// Represents a user stored in the Firestore `users` collection.
/// The document ID matches the Firebase Auth uid.
struct AppUser: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var displayName: String

    init(id: String? = nil, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

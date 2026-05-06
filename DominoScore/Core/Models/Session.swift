//
//  Session.swift
//  DominoScore
//

import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: String
    var code: String
    var hostId: String
    var participants: [Participant]
    var scoreEntries: [ScoreEntry]
    var createdAt: Date
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        code: String,
        hostId: String,
        participants: [Participant] = [],
        scoreEntries: [ScoreEntry] = [],
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.code = code
        self.hostId = hostId
        self.participants = participants
        self.scoreEntries = scoreEntries
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    static let mock: Session = .init(
        id: "123",
        code: "ABC123",
        hostId: "456",
        participants: [
            .init(id: "456", name: "John Doe"),
            .init(id: "789", name: "Jane Smith")
        ],
        scoreEntries: [])
}

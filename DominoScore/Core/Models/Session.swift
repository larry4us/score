//
//  Session.swift
//  DominoScore
//

import Foundation

struct Session: Identifiable, Codable {
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
}

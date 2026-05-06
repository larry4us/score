//
//  ScoreEvent.swift
//  DominoScore
//

import Foundation

enum ScoreEventType: String, Codable {
    case scoreAdded
    case scoreUpdated
    case scoreRemoved
    case roundCompleted
}

struct ScoreEvent: Identifiable, Codable {
    let id: String
    var sessionId: String
    var participantId: String
    var type: ScoreEventType
    var points: Int
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        participantId: String,
        type: ScoreEventType,
        points: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.participantId = participantId
        self.type = type
        self.points = points
        self.timestamp = timestamp
    }
}

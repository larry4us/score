//
//  ScoreEntry.swift
//  DominoScore
//

import Foundation

struct ScoreEntry: Identifiable, Codable, Hashable {
    let id: String
    var participantId: String
    var points: Int
    var round: Int
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        participantId: String,
        points: Int,
        round: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.participantId = participantId
        self.points = points
        self.round = round
        self.timestamp = timestamp
    }
}

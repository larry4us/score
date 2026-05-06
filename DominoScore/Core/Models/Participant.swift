//
//  Participant.swift
//  DominoScore
//

import Foundation

struct Participant: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var totalScore: Int
    var joinedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        totalScore: Int = 0,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.totalScore = totalScore
        self.joinedAt = joinedAt
    }
}

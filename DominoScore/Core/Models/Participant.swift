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
    var teamColorIndex: Int
    var ownerUid: String

    enum CodingKeys: String, CodingKey {
        case id, name, totalScore, joinedAt, teamColorIndex, ownerUid
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        totalScore: Int = 0,
        joinedAt: Date = .now,
        teamColorIndex: Int = 0,
        ownerUid: String = ""
    ) {
        self.id = id
        self.name = name
        self.totalScore = totalScore
        self.joinedAt = joinedAt
        self.teamColorIndex = teamColorIndex
        self.ownerUid = ownerUid
    }

    /// Backward-compatible decoding — old documents without teamColorIndex/ownerUid still decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        totalScore = try container.decode(Int.self, forKey: .totalScore)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        teamColorIndex = try container.decodeIfPresent(Int.self, forKey: .teamColorIndex) ?? 0
        ownerUid = try container.decodeIfPresent(String.self, forKey: .ownerUid) ?? ""
    }
    
    //MARK: -- mock
    
    static let mockList: [Participant] = [
        Participant(name: "João", totalScore: 120, teamColorIndex: 0, ownerUid: "mock-uid"),
        Participant(name: "Maria", totalScore: 85, teamColorIndex: 1, ownerUid: "joiner-1"),
        Participant(name: "Pedro", totalScore: 200, teamColorIndex: 2, ownerUid: "joiner-2"),
        Participant(name: "Ana", totalScore: 50, teamColorIndex: 2, ownerUid: "joiner-3")
    ]
}

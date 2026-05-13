//
//  Session.swift
//  DominoScore
//

import Foundation
import FirebaseFirestore

struct Session: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var code: String
    var hostUid: String
    var status: Status
    var participants: [Participant]
    
    var displayName: String {
        switch status {
        case .active: return "Ativo"
        case .finished: return "Finalizado"
        case .waiting: return "Lobby"
        }
    }
    
    enum Status: String, Codable, Hashable {
        case waiting
        case active
        case finished
    }

    enum GameMode: String, Codable, Hashable {
        case online
        case offline
    }

    var mode: GameMode = .online

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case hostUid
        case status
        case participants
        case mode
    }

    init(
        id: String? = nil,
        code: String,
        hostUid: String,
        status: Status,
        mode: GameMode = .online,
        participants: [Participant] = []
    ) {
        self.id = id
        self.code = code
        self.hostUid = hostUid
        self.status = status
        self.mode = mode
        self.participants = participants
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        hostUid = try container.decode(String.self, forKey: .hostUid)
        status = try container.decode(Status.self, forKey: .status)
        participants = try container.decode([Participant].self, forKey: .participants)
        mode = try container.decodeIfPresent(GameMode.self, forKey: .mode) ?? .online
    }

    // MARK: - Mock

    static let mock = Session(
        code: "AB3K7",
        hostUid: "mock-uid",
        status: .waiting,
        participants: Participant.mockList
    )
}

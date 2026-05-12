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

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case hostUid
        case status
        case participants
    }

    init(
        id: String? = nil,
        code: String,
        hostUid: String,
        status: Status,
        participants: [Participant] = []
    ) {
        self.id = id
        self.code = code
        self.hostUid = hostUid
        self.status = status
        self.participants = participants
    }

    // MARK: - Mock

    static let mock = Session(
        code: "AB3K7",
        hostUid: "mock-uid",
        status: .waiting,
        participants: Participant.mockList
    )
}

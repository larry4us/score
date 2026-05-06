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
    }

    // MARK: - Mock

    static let mock = Session(
        code: "AB3K7",
        hostUid: "mock-uid",
        status: .waiting
    )
}

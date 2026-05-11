//
//  Team.swift
//  DominoScore
//

import SwiftUI

/// View-model that groups participants by team color.
/// Not stored in Firestore — computed from the participant array.
struct Team: Identifiable, Hashable {
    let colorIndex: Int
    var participants: [Participant]

    var id: Int { colorIndex }

    /// Sum of all participant scores in this team.
    var totalScore: Int {
        participants.reduce(0) { $0 + $1.totalScore }
    }

    /// Comma-separated member names for display.
    var memberNames: String {
        participants.map(\.name).joined(separator: ", ")
    }

    /// Whether a given uid belongs to this team.
    func containsOwner(uid: String) -> Bool {
        participants.contains { $0.ownerUid == uid }
    }

    /// The SwiftUI Color for this team.
    var color: Color {
        Self.color(for: colorIndex)
    }

    /// Maps color index to SwiftUI Color.
    static func color(for index: Int) -> Color {
        switch index {
        case 0: .red
        case 1: .blue
        case 2: .green
        case 3: .yellow
        default: .gray
        }
    }

    /// Maps color index to a localized display name.
    static func name(for index: Int) -> String {
        switch index {
        case 0: "Vermelho"
        case 1: "Azul"
        case 2: "Verde"
        case 3: "Amarelo"
        default: "Time \(index + 1)"
        }
    }

    /// Number of available team colors.
    static let availableColors = 4
}

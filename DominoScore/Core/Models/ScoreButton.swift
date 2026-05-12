//
//  ScoreButton.swift
//  DominoScore
//

import Foundation

/// Represents a configurable score button.
/// When `isGalo` is true, the button displays a rooster icon and always adds 50 points.
struct ScoreButton: Codable, Identifiable, Hashable {
    var id = UUID()
    var value: Int
    var isGalo: Bool

    init(value: Int, isGalo: Bool = false) {
        self.value = isGalo ? 50 : value
        self.isGalo = isGalo
    }

    /// Display label for the button (used in the game).
    var label: String {
        isGalo ? "🐓" : "\(value)"
    }

    static let defaultButtons: [ScoreButton] = [
        ScoreButton(value: 5),
        ScoreButton(value: 10),
        ScoreButton(value: 25),
        ScoreButton(value: 50)
    ]
}

// MARK: - JSON Helpers

extension [ScoreButton] {
    /// Encode to JSON string for persistence.
    var jsonString: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    /// Decode from JSON string.
    init(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([ScoreButton].self, from: data) else {
            self = ScoreButton.defaultButtons
            return
        }
        self = decoded
    }
}

//
//  CodeGenerator.swift
//  DominoScore
//

import Foundation

/// Generates short, readable session codes for players to join.
struct CodeGenerator {

    private static let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    private static let codeLength = 5

    /// Generates a random alphanumeric code (e.g. "A3K7P2").
    func generate() -> String {
        let chars = Array(Self.characters)
        return String((0..<Self.codeLength).map { _ in chars.randomElement()! })
    }
}

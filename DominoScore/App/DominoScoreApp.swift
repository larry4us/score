//
//  DominoScoreApp.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 03/05/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct DominoScoreApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            CoordinatorView()
        }
    }
}


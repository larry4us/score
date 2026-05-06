//
//  AppDelegate.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 03/05/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("Firebase configurado!")
      
    return true
  }
}


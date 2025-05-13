//
//  AppDevApp.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import UIKit
import FirebaseCore

@main
class AppDevApp: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


//
//  social_batteryApp.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import SwiftUI
import Amplify
import Authenticator
import AWSCognitoAuthPlugin

@main
struct social_batteryApp: App {
        init() {
                do {
                    try Amplify.add(plugin: AWSCognitoAuthPlugin())
                    try Amplify.configure(with: .amplifyOutputs)
                } catch {
                    print("Unable to configure Amplify \(error)")
                }
            }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

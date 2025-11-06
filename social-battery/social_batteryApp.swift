//
//  social_batteryApp.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import SwiftUI
import UIKit
import UserNotifications
import Amplify
import Authenticator
import AWSCognitoAuthPlugin

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        Task {
            do {
                // attempt to fetch signed-in user's email
                var email: String? = nil
                do {
                    let attrs = try await Amplify.Auth.fetchUserAttributes()
                    if let emailAttr = attrs.first(where: { $0.key.rawValue == "email" }) { email = emailAttr.value }
                } catch {
                    // ignore
                }
                try await ConnectionsAPI.shared.registerDeviceToken(token, forEmail: email)
            } catch {
                print("Failed to register device token: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct social_batteryApp: App {
    // wire up app delegate for remote notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(with: .amplifyOutputs)
        } catch {
            print("Unable to configure Amplify \(error)")
        }
        // request permission for local notifications and register for remote
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let e = error { print("Notif auth error: \(e)") }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

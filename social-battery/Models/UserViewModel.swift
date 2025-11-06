//
//  UserViewModel.swift
//  social-battery
//
//  Created by Nicholas Morris on 6/11/2025.
//

import Amplify
import Foundation
import Combine
import AWSCognitoAuthPlugin

@MainActor
public final class UserViewModel: ObservableObject {
    @Published var email: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var signedIn: Bool?

    func loadUserAttributes() async {
        isLoading = true
        error = nil
        signedIn = false

        do {
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            if let emailAttr = attributes.first(where: { $0.key.rawValue == "email" }) {
                email = emailAttr.value
                signedIn = true
            }
        } catch {
            self.error = "Failed to fetch user attributes: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

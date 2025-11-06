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

    private var hubListener: UnsubscribeToken?

    public init() {
        // listen to auth events to update UI reactively
        hubListener = Amplify.Hub.listen(to: .auth) { [weak self] payload in
            Task { @MainActor in
                await self?.refreshAuthState()
            }
        }
        Task { @MainActor in await refreshAuthState() }
    }

    deinit {
        if let token = hubListener { Amplify.Hub.removeListener(token) }
    }

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

    private func refreshAuthState() async {
        isLoading = true
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                signedIn = true
                do {
                    let attributes = try await Amplify.Auth.fetchUserAttributes()
                    if let emailAttr = attributes.first(where: { $0.key.rawValue == "email" }) {
                        email = emailAttr.value
                    }
                } catch {
                    email = nil
                }
            } else {
                signedIn = false
                email = nil
            }
        } catch {
            signedIn = nil
            print("Auth fetch failed")
        }
        isLoading = false
    }
}

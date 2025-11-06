import Foundation
import Amplify

/// Simple HTTP client wrapper for the connections backend.
/// NOTE: This is a lightweight scaffold. You must deploy the server endpoint (API Gateway + Lambda)
/// and set `baseURL` to the deployed endpoint. The API should accept JSON payloads and be secured
/// (preferably using Cognito JWT Bearer tokens).
final class ConnectionsAPI {
    static let shared = ConnectionsAPI()

    // Replace with your deployed API endpoint, e.g. https://abc123.execute-api.us-east-1.amazonaws.com/prod
    var baseURL: URL? = nil

    private init() {}

    private func authHeader() async -> String? {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            // Attempt to extract tokens from Cognito plugin if present
            if let _ = session as? AuthSession {
                // Amplify currently doesn't expose token fetching in a stable cross-plugin API
                // Implement token retrieval here if using a specific auth plugin.
            }
            // As a fallback, return nil: anonymous requests are allowed only if your API permits it.
            return nil
        } catch {
            return nil
        }
    }

    func sendConnectionRequest(_ request: ConnectionRequest) async throws {
        guard let base = baseURL else { throw URLError(.badURL) }
        let url = base.appendingPathComponent("connections")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await authHeader() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONEncoder().encode(request)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        _ = data // ignore body for now
    }

    func fetchIncomingRequests(forEmail email: String) async throws -> [ConnectionRequest] {
        guard let base = baseURL else { throw URLError(.badURL) }
        var comps = URLComponents(url: base.appendingPathComponent("connections"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "receiverEmail", value: email)]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        if let token = await authHeader() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([ConnectionRequest].self, from: data)
    }

    func updateBattery(forEmail email: String, percent: Int) async throws {
        guard let base = baseURL else { throw URLError(.badURL) }
        let url = base.appendingPathComponent("connections/battery")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await authHeader() { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        struct BatteryUpdatePayload: Encodable { let email: String; let battery: Int }
        let body = BatteryUpdatePayload(email: email, battery: percent)
        req.httpBody = try JSONEncoder().encode(body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func registerDeviceToken(_ token: String, forEmail email: String?) async throws {
        guard let base = baseURL else { throw URLError(.badURL) }
        let url = base.appendingPathComponent("devices")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = await authHeader() { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let body: [String: Any?] = ["token": token, "email": email]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}


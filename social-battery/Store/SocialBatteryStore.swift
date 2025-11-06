//
//  SocialBatteryStore.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
final class SocialBatteryStore: ObservableObject {
    @Published var friends: [Friend]
    @Published var availability: Availability
    @Published var frequency: FrequencyLimit
    @Published var incomingRequests: [ConnectionRequest] = []
    @Published var sentRequests: [ConnectionRequest] = []
    @Published var scheduledMeetings: [ScheduledMeeting] = []

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("social_battery.json")
    }()

    init(friends: [Friend] = [], availability: Availability = .weekends, frequency: FrequencyLimit = .timesPerWeek(1)) {
        if let loaded = try? Self.load(from: saveURL) {
            self.friends = loaded.friends
            self.availability = loaded.availability
            self.frequency = loaded.frequency
        } else {
            self.friends = friends.isEmpty ? Self.sampleFriends() : friends
            self.availability = availability
            self.frequency = frequency
        }
        // Request notification permissions for local notifications (dev-friendly)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let err = error { print("Notification auth error: \(err)") }
        }
    }

    func addFriend(name: String, color: Color = .blue, maxFrequency: FrequencyLimit? = nil) {
        friends.append(Friend(name: name, color: color, lastMet: nil, maxFrequency: maxFrequency))
        persist()
    }

    // Schedule a meeting (does not mark lastMet). Accepting a meeting will set lastMet.
    func scheduleMeeting(with friendID: UUID, on date: Date = .now) {
        let meeting = ScheduledMeeting(friendID: friendID, date: date)
        scheduledMeetings.append(meeting)
        persist()
    }

    func acceptMeeting(_ meetingID: UUID) {
        guard let idx = scheduledMeetings.firstIndex(where: { $0.id == meetingID }) else { return }
        scheduledMeetings[idx].accepted = true
        // mark friend as met at meeting date
        let m = scheduledMeetings[idx]
        if let fidx = friends.firstIndex(where: { $0.id == m.friendID }) {
            friends[fidx].lastMet = m.date
        }
        persist()
    }

    func status(for friend: Friend, from: Date = .now) -> BatteryStatus {
        // If friend publishes their battery level, prefer that value (for remote friends).
        if let published = friend.batteryLevel {
            // build a BatteryStatus with next recommended date from engine but percent from published value
            let engine = BatteryEngine.status(for: friend, policy: .global(availability: availability, frequency: frequency), from: from)
            return BatteryStatus(percent: max(0, min(100, published)), nextRecommendedDate: engine.nextRecommendedDate)
        }
        // compute locally using BatteryEngine
        let computed = BatteryEngine.status(for: friend, policy: .global(availability: availability, frequency: frequency), from: from)
        // If this friend is associated with a remote owner, publish computed battery to backend
        if let owner = friend.ownerEmail {
            Task {
                do {
                    try await ConnectionsAPI.shared.updateBattery(forEmail: owner, percent: computed.percent)
                } catch {
                    print("Failed to publish battery for \(owner): \(error)")
                }
            }
        }
        return computed
    }

    // MARK: - Connections
    func sendConnectionRequest(senderEmail: String, receiverEmail: String, preferences: String?) {
        let req = ConnectionRequest(senderEmail: senderEmail, receiverEmail: receiverEmail, preferences: preferences)
        sentRequests.append(req)
        persist()
        // Try to send to backend if configured
        Task {
            do {
                try await ConnectionsAPI.shared.sendConnectionRequest(req)
            } catch {
                print("ConnectionsAPI send failed: \(error)")
            }
        }
    }

    func receiveConnectionRequest(_ req: ConnectionRequest) {
        incomingRequests.append(req)
        persist()
        // schedule a local notification to inform the receiver
        let content = UNMutableNotificationContent()
        content.title = "New friend request"
        content.body = "Request from \(req.senderEmail)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: req.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let e = error { print("Failed to schedule notification: \(e)") }
        }
    }

    func acceptConnectionRequest(_ requestID: UUID) {
        guard let idx = incomingRequests.firstIndex(where: { $0.id == requestID }) else { return }
        var req = incomingRequests.remove(at: idx)
        req.status = .accepted
        // find sender in friends or add placeholder friend
        if !friends.contains(where: { $0.name == req.senderEmail }) {
            friends.append(Friend(name: req.senderEmail, color: .gray))
        }
        persist()
    }

    func cancelSentRequest(_ requestID: UUID) {
        if let idx = sentRequests.firstIndex(where: { $0.id == requestID }) {
            sentRequests.remove(at: idx)
            persist()
        }
    }

    func updateSettings(availability: Availability, frequency: FrequencyLimit) {
        self.availability = availability
        self.frequency = frequency
        persist()
    }

    // MARK: - Persistence
    private func persist() {
        do { try Self.save(store: self, to: saveURL) } catch { print("Save failed: \(error)") }
    }

    private struct Snapshot: Codable {
        var friends: [Friend]
        var availability: Availability
        var frequency: FrequencyLimit
        var incomingRequests: [ConnectionRequest]
        var sentRequests: [ConnectionRequest]
        var scheduledMeetings: [ScheduledMeeting]
    }

    private static func save(store: SocialBatteryStore, to url: URL) throws {
        let snap = Snapshot(friends: store.friends, availability: store.availability, frequency: store.frequency, incomingRequests: store.incomingRequests, sentRequests: store.sentRequests, scheduledMeetings: store.scheduledMeetings)
        let data = try JSONEncoder().encode(snap)
        try data.write(to: url, options: .atomic)
    }

    private static func load(from url: URL) throws -> Snapshot {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Snapshot.self, from: data)
    }

    // MARK: - Sample Data
    static func sampleFriends() -> [Friend] {
        [
            Friend(name: "Robyn", color: .blue, lastMet: Calendar.current.date(byAdding: .day, value: -2, to: .now)),
            Friend(name: "Tess", color: .orange, lastMet: Calendar.current.date(byAdding: .day, value: -10, to: .now), maxFrequency: .timesPerMonth(2)),
            Friend(name: "Lily", color: .pink, lastMet: Calendar.current.date(byAdding: .day, value: -60, to: .now), maxFrequency: .timesPerMonth(1))
        ]
    }
}

//
//  SocialBatteryStore.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SocialBatteryStore: ObservableObject {
    @Published var friends: [Friend]
    @Published var availability: Availability
    @Published var frequency: FrequencyLimit

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
    }

    func addFriend(name: String, color: Color = .blue, maxFrequency: FrequencyLimit? = nil) {
        friends.append(Friend(name: name, color: color, lastMet: nil, maxFrequency: maxFrequency))
        persist()
    }

    func recordMeeting(with friendID: UUID, on date: Date = .now) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }
        friends[idx].lastMet = date
        persist()
    }

    func status(for friend: Friend, from: Date = .now) -> BatteryStatus {
        BatteryEngine.status(for: friend, policy: .global(availability: availability, frequency: frequency), from: from)
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
    }

    private static func save(store: SocialBatteryStore, to url: URL) throws {
        let snap = Snapshot(friends: store.friends, availability: store.availability, frequency: store.frequency)
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

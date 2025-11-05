//
//  Friends.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Frequency and availability

public enum FrequencyLimit: Equatable, Codable, Sendable {
    case timesPerWeek(Int)
    case timesPerMonth(Int)

    public var daysInterval: Int {
        switch self {
        case .timesPerWeek(let n):
            return max(1, 7 / max(n, 1))
        case .timesPerMonth(let n):
            return max(1, 30 / max(n, 1))
        }
    }
}

public struct Availability: Equatable, Codable, Sendable {
    // Calendar.component(.weekday): 1=Sunday ... 7=Saturday
    public var allowedWeekdays: Set<Int>
    public var notes: String?

    public init(allowedWeekdays: Set<Int>, notes: String? = nil) {
        self.allowedWeekdays = allowedWeekdays
        self.notes = notes
    }

    public static let weekends = Availability(allowedWeekdays: [1,7])
    public static let weekdays = Availability(allowedWeekdays: [2,3,4,5,6])

    public static func specific(_ days: [Int], notes: String? = nil) -> Availability {
        .init(allowedWeekdays: Set(days), notes: notes)
    }

    public func nextMatchingDate(from: Date = .now, calendar: Calendar = .current) -> Date {
        var date = calendar.startOfDay(for: from)
        for _ in 0..<28 { // search up to 4 weeks
            let weekday = calendar.component(.weekday, from: date)
            if allowedWeekdays.contains(weekday) { return date }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }
}

// MARK: - Friend model

public struct Friend: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var color: ColorCodable
    public var lastMet: Date?
    public var maxFrequency: FrequencyLimit?

    public init(id: UUID = UUID(), name: String, color: Color = .blue, lastMet: Date? = nil, maxFrequency: FrequencyLimit? = nil) {
        self.id = id
        self.name = name
        self.color = ColorCodable(color)
        self.lastMet = lastMet
        self.maxFrequency = maxFrequency
    }

    public var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let last = parts.dropFirst().first?.first.map(String.init)
        return (first + (last ?? "")).uppercased()
    }
}

// MARK: - Battery

public struct BatteryStatus: Equatable, Sendable {
    public var percent: Int
    public var nextRecommendedDate: Date
}

public enum SocialPolicy {
    case global(availability: Availability, frequency: FrequencyLimit)
}

public struct BatteryEngine {
    public static func status(for friend: Friend, policy: SocialPolicy, calendar: Calendar = .current, from: Date = .now) -> BatteryStatus {
        let effectiveFrequency: FrequencyLimit
        let availability: Availability
        switch policy {
        case .global(let avail, let freq):
            availability = avail
            effectiveFrequency = friend.maxFrequency ?? freq
        }
        let days = effectiveFrequency.daysInterval

        let base = friend.lastMet.map { calendar.date(byAdding: .day, value: days, to: $0) ?? from } ?? from
        let next = availability.nextMatchingDate(from: base, calendar: calendar)

        let last = friend.lastMet ?? calendar.date(byAdding: .day, value: -days, to: from)!
        let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: from)).day ?? 0
        let ratio = min(1.0, Double(daysSince) / Double(days))
        let percent = max(0, 100 - Int(ratio * 100))
        return BatteryStatus(percent: percent, nextRecommendedDate: next)
    }
}

// MARK: - Codable Color wrapper

public struct ColorCodable: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }

    public var color: Color { Color(red: red, green: green, blue: blue, opacity: opacity) }
}

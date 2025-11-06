import XCTest
@testable import social_battery

final class SocialBatteryTests: XCTestCase {

    func test_send_and_accept_connection_request() {
        let store = SocialBatteryStore()
        XCTAssertEqual(store.incomingRequests.count, 0)
        XCTAssertEqual(store.sentRequests.count, 0)

        store.sendConnectionRequest(senderEmail: "alice@example.com", receiverEmail: "bob@example.com", preferences: "weekends")
        XCTAssertEqual(store.sentRequests.count, 1)

        // simulate receiver receiving it
        if let req = store.sentRequests.first {
            store.receiveConnectionRequest(req)
        }
        XCTAssertEqual(store.incomingRequests.count, 1)

        if let req = store.incomingRequests.first {
            store.acceptConnectionRequest(req.id)
        }

        XCTAssertTrue(store.friends.contains(where: { $0.name == "alice@example.com" }))
    }

    func test_battery_engine_basic() {
        let friend = Friend(name: "Test", lastMet: Calendar.current.date(byAdding: .day, value: -3, to: .now))
        let status = BatteryEngine.status(for: friend, policy: .global(availability: .weekends, frequency: .timesPerWeek(1)), from: .now)
        XCTAssert(status.percent >= 0 && status.percent <= 100)
    }
}
//
//  social_batteryTests.swift
//  social-batteryTests
//
//  Created by Nicholas Morris on 5/11/2025.
//

import Testing

struct social_batteryTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

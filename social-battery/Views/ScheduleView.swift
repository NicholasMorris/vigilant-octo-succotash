//
//  ScheduleView.swift
//  social battery
//
//  Created by Nicholas Morris on 3/11/2025.
//

import SwiftUI

struct ScheduleSheet: View {
    let friend: Friend
    @ObservedObject var store: SocialBatteryStore
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Meet on", selection: $date, displayedComponents: [.date])
            }
            .navigationTitle("Schedule with \(friend.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.recordMeeting(with: friend.id, on: date)
                        dismiss()
                    }
                }
            }
        }
    }
}

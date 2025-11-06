//
//  ContentView.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = SocialBatteryStore()
    @State private var showingAddFriend = false
    @State private var selectedFriendForSchedule: Friend? = nil
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    statsRow
                    friendsList
                }
                .padding()
            }
            .navigationTitle("Social Battery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddFriend = true }) {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) { AddFriendSheet(store: store) }
            .sheet(item: $selectedFriendForSchedule) { friend in ScheduleSheet(friend: friend, store: store) }
            .sheet(isPresented: $showingSettings) { SettingsView(store: store) }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.batteryblock.fill")
                .foregroundStyle(.green)
            Text("Social Battery")
                .font(.largeTitle.bold())
        }
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Total Friends", value: "\(store.friends.count)", color: .blue)
            statCard(title: "Avg Energy", value: "\(averageBattery)%", color: .green)
            statCard(title: "Need Recharge", value: "\(needRechargeCount)", color: .orange)
        }
    }

    private var friendsList: some View {
        VStack(spacing: 16) {
            ForEach(store.friends) { friend in
                let status = store.status(for: friend)
                FriendRowView(friend: friend, status: status) {
                    selectedFriendForSchedule = friend
                }
            }
        }
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var averageBattery: Int {
        guard !store.friends.isEmpty else { return 0 }
        let total = store.friends.map { store.status(for: $0).percent }.reduce(0, +)
        return total / store.friends.count
    }

    private var needRechargeCount: Int {
        store.friends.filter { store.status(for: $0).percent < 25 }.count
    }
}

// MARK: - Add Friend Sheet

private struct AddFriendSheet: View {
    @ObservedObject var store: SocialBatteryStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var perFriendLimit: Bool = false
    @State private var times: Int = 1
    @State private var per: Int = 1 // 1=week, 2=month

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                }
                Section("Per-friend limit (optional)") {
                    Toggle("Enable", isOn: $perFriendLimit)
                    if perFriendLimit {
                        Stepper("Times: \(times)", value: $times, in: 1...7)
                        Picker("Per", selection: $per) {
                            Text("Week").tag(1)
                            Text("Month").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let limit: FrequencyLimit? = perFriendLimit ? (per == 1 ? .timesPerWeek(times) : .timesPerMonth(times)) : nil
                        store.addFriend(name: name.isEmpty ? "Friend" : name, color: color, maxFrequency: limit)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

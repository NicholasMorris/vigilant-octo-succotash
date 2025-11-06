//
//  ContentView.swift
//  social-battery
//
//  Created by Nicholas Morris on 5/11/2025.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

struct ContentView: View {
    @StateObject private var store = SocialBatteryStore()
    @State private var showingAddFriend = false
    @State private var selectedFriendForSchedule: Friend? = nil
    @State private var showingSettings = false
        @State private var showingFriendRequests = false

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
                        HStack {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                            }
                            Button(action: { showingFriendRequests = true }) {
                                Image(systemName: "person.2.fill")
                            }
                        }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddFriend = true }) {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) { AddFriendSheet(store: store) }
                .sheet(isPresented: $showingFriendRequests) { FriendRequestsView(store: store) }
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
    @State private var email: String = ""
    @State private var preferences: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name or display", text: $name)
                    TextField("Friend email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                }
                Section("Preferences (optional)") {
                    TextField("Preferences (availability, notes)", text: $preferences)
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
                    Button("Send Request") {
                        // attempt to fetch sender email from Amplify Auth attributes; fall back to name
                        Task {
                            var sender = name
                            do {
                                let attrs = try await Amplify.Auth.fetchUserAttributes()
                                if let emailAttr = attrs.first(where: { $0.key.rawValue == "email" }) {
                                    sender = emailAttr.value
                                }
                            } catch {
                                // ignore
                            }
                            store.sendConnectionRequest(senderEmail: sender, receiverEmail: email, preferences: preferences.isEmpty ? nil : preferences)
                            dismiss()
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

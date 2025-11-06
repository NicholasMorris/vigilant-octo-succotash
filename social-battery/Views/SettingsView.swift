//
//  SettingsView.swift
//  social battery
//
//  Created by Nicholas Morris on 3/11/2025.
//

import SwiftUI
import Amplify
import Authenticator

struct AuthFlow: View {
    var body: some View {
        Authenticator { state in
            VStack {
                Button("Sign out") {
                    Task {
                        await state.signOut()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SocialBatteryStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = UserViewModel()
    
    @State private var selection: Int = 0 // 0=weekends, 1=weekdays, 2=custom
    @State private var customDays: Set<Int> = []
    @State private var times: Int = 1
    @State private var per: Int = 1 // 1=week, 2=month
    @State private var email: String?
    @State private var showSignin: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    if vm.isLoading {
                        ProgressView("Loading…")
                    } else if let _ = vm.signedIn {
                        if let email = vm.email {
                            Text("Email: \(email)")
                        } else if let error = vm.error {
                            Button(action: { showSignin = true }) {
                                Text("Sign In")
                            }
                            Text(error)
                                .foregroundColor(.red)
                        }
//                        AuthFlow()
                    } else {
                        
                    }
                    Button("Fetch Attributes") {
                        Task {
                            do {
                                let userAttributes = try await Amplify.Auth.fetchUserAttributes()
                                print(userAttributes[0].value)
                            } catch {
                                print("Failed to fetch attributes:", error)
                            }
                        }
                    }

                }
                Section("Availability") {
                    Picker("Preset", selection: $selection) {
                        Text("Weekends").tag(0)
                        Text("Weekdays").tag(1)
                        Text("Custom").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    if selection == 2 {
                        WeekdayPicker(selection: $customDays)
                        Text("Choose one or more days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Frequency") {
                    Stepper("Times: \(times)", value: $times, in: 1...7)
                    Picker("Per", selection: $per) {
                        Text("Week").tag(1)
                        Text("Month").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let availability: Availability
                        switch selection {
                        case 0: availability = .weekends
                        case 1: availability = .weekdays
                        default: availability = .specific(Array(customDays))
                        }
                        let freq: FrequencyLimit = per == 1 ? .timesPerWeek(times) : .timesPerMonth(times)
                        store.updateSettings(availability: availability, frequency: freq)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSignin) { AuthFlow() }
            .onAppear {
                // hydrate UI from store
                switch store.availability.allowedWeekdays.sorted() {
                case [1,7]: selection = 0
                case [2,3,4,5,6]: selection = 1
                default:
                    selection = 2
                    customDays = store.availability.allowedWeekdays
                }
                switch store.frequency {
                case .timesPerWeek(let n):
                    per = 1; times = n
                case .timesPerMonth(let n):
                    per = 2; times = n
                }
            }
            .task {      // <-- SwiftUI waits and re-renders when done
                await vm.loadUserAttributes()
            }
        }
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    private let symbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { day in
                let isOn = selection.contains(day)
                Button(action: {
                    if isOn { selection.remove(day) } else { selection.insert(day) }
                }) {
                    Text(symbols[day-1])
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isOn ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isOn ? Color.accentColor : .secondary, lineWidth: 1))
                }
            }
        }
    }
}


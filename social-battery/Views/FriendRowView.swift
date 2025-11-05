//
//  FriendRowView.swift
//  social battery
//
//  Created by Nicholas Morris on 3/11/2025.
//

import SwiftUI

struct FriendRowView: View {
    let friend: Friend
    let status: BatteryStatus
    var scheduleAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Next")
                        .foregroundStyle(.secondary)
                    Text(status.nextRecommendedDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button(action: scheduleAction) {
                    Label("Schedule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .font(.subheadline)
                .padding(.top, 4)
            }
            Spacer()
            battery
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(friend.color.color.gradient)
                .frame(width: 58, height: 58)
            Text(friend.initials)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    private var battery: some View {
        VStack(alignment: .trailing) {
            Image(systemName: batterySymbol)
                .font(.system(size: 28))
                .foregroundStyle(batteryColor)
            Text("\(status.percent)%")
                .font(.caption)
                .foregroundStyle(batteryColor)
        }
        .frame(minWidth: 56)
    }

    private var batterySymbol: String {
        switch status.percent {
        case 75...100: return "battery.100"
        case 50..<75: return "battery.75"
        case 25..<50: return "battery.25"
        default: return "battery.0"
        }
    }

    private var batteryColor: Color {
        switch status.percent {
        case 60...100: return .green
        case 25..<60: return .yellow
        default: return .red
        }
    }
}

#Preview {
    let friend = Friend(name: "Tess", color: .orange, lastMet: .now)
    let engineStatus = BatteryEngine.status(for: friend, policy: .global(availability: .weekends, frequency: .timesPerWeek(1)))
    return FriendRowView(friend: friend, status: engineStatus, scheduleAction: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

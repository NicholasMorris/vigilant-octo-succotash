import SwiftUI

struct FriendRequestsView: View {
    @ObservedObject var store: SocialBatteryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !store.incomingRequests.isEmpty {
                    Section("Incoming") {
                        ForEach(store.incomingRequests) { req in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(req.senderEmail)
                                    Text(req.preferences ?? "No prefs").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Accept") { store.acceptConnectionRequest(req.id) }
                            }
                        }
                    }
                }

                if !store.sentRequests.isEmpty {
                    Section("Sent") {
                        ForEach(store.sentRequests) { req in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(req.receiverEmail)
                                    Text(req.preferences ?? "No prefs").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Cancel") { store.cancelSentRequest(req.id) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    FriendRequestsView(store: SocialBatteryStore())
}

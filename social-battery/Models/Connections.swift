import Foundation

public enum ConnectionStatus: String, Codable, Sendable {
    case pending
    case accepted
    case rejected
}

public struct ConnectionRequest: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var senderEmail: String
    public var receiverEmail: String
    public var preferences: String?
    public var sentAt: Date
    public var status: ConnectionStatus

    public init(id: UUID = UUID(), senderEmail: String, receiverEmail: String, preferences: String? = nil, sentAt: Date = .now, status: ConnectionStatus = .pending) {
        self.id = id
        self.senderEmail = senderEmail
        self.receiverEmail = receiverEmail
        self.preferences = preferences
        self.sentAt = sentAt
        self.status = status
    }
}

public struct ScheduledMeeting: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var friendID: UUID
    public var date: Date
    public var createdAt: Date
    public var accepted: Bool

    public init(id: UUID = UUID(), friendID: UUID, date: Date, createdAt: Date = .now, accepted: Bool = false) {
        self.id = id
        self.friendID = friendID
        self.date = date
        self.createdAt = createdAt
        self.accepted = accepted
    }
}

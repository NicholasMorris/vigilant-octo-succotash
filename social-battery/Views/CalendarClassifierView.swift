import SwiftUI
import EventKit
import Combine
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct CalendarEventInfo: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    var isSocial: Bool? = nil
}

@MainActor
final class CalendarClassifierViewModel: ObservableObject {
    // provide the default ObservableObjectPublisher and a safe initializer
    var objectWillChange: ObservableObjectPublisher

    @Published var events: [CalendarEventInfo] = []
    private let store = EKEventStore()

#if canImport(FoundationModels)
    // Optional on-device language model session (only compiled when FoundationModels is available)
    private var lmSession: LanguageModelSession?
#endif

    init() {
        self.objectWillChange = ObservableObjectPublisher()
#if canImport(FoundationModels)
        // Try to create a session if the runtime provides the Foundation Models framework
        if #available(iOS 17.0, macOS 14.0, *) {
            // Defensive: SystemLanguageModel and LanguageModelSession initializers can differ across SDKs
            // Try to obtain a default system model and create a session; fall back silently if unavailable
            do {
                let model = SystemLanguageModel.default
                lmSession = try? LanguageModelSession(model: model)
            } catch {
                lmSession = nil
            }
        }
#endif
    }

    func requestAccessAndLoad() async {
        do {
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .notDetermined {
                let granted = try await store.requestAccess(to: .event)
                guard granted else { return }
            }
            loadUpcoming()
        } catch {
            print("Calendar access error: \(error)")
        }
    }

    func loadUpcoming() {
        let cal = Calendar.current
        let start = Date()
        let end = cal.date(byAdding: .day, value: 30, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)
        self.events = ekEvents.map { CalendarEventInfo(title: $0.title ?? "(no title)", startDate: $0.startDate, endDate: $0.endDate) }
    }

    func classifyLocally() {
        // simple heuristic classifier using keywords and duration
        let socialKeywords = ["party","dinner","lunch","drinks","meet","coffee","birthday","wedding","date","hang","bar","restaurant","concert"]
        for idx in events.indices {
            let e = events[idx]
            let lower = e.title.lowercased()
            let keywordMatch = socialKeywords.contains { lower.contains($0) }
            let duration = e.endDate.timeIntervalSince(e.startDate)
            let isLong = duration > (60*60) // >1 hour
            events[idx].isSocial = keywordMatch || isLong
        }
    }

    // Example prompt (from the attached transcript) to run with an on-device foundation model:
    // "Classify the following calendar event as social or not social. Provide a probability and short rationale. Event title: <title>. Start: <start>. End: <end>."
    // In this repo we implement a local heuristic but the prompt above is suitable for the Foundation Models Framework one-shot or guided generation.

    // Async classification using on-device language model when available.
    // Falls back to heuristic otherwise.
    func classifyWithModel() async {
#if canImport(FoundationModels)
        guard let session = lmSession else {
            classifyLocally()
            return
        }

        for idx in events.indices {
            let ev = events[idx]
            let prompt = "Classify the following calendar event as social or not social. Provide a probability (0-1) and a one-sentence rationale. Event title: \(ev.title). Start: \(ev.startDate). End: \(ev.endDate)."
            do {
                let response = try await session.respond(to: prompt)
                // response.content may be a String or another structure depending on SDK; handle defensively
                let text: String
                if let c = response.content as? String {
                    text = c
                } else if let c = String(describing: response.content) as String? {
                    text = c
                } else {
                    text = ""
                }

                let lower = text.lowercased()
                var result: Bool? = nil
                if lower.contains("social") && !lower.contains("not social") {
                    result = true
                } else if lower.contains("not social") {
                    result = false
                } else if let probMatch = lower.range(of: "[0-9]*\\.?[0-9]+", options: .regularExpression) {
                    let probStr = String(lower[probMatch])
                    if let p = Double(probStr) {
                        result = p >= 0.5
                    }
                }

                if result == nil {
                    // fallback heuristic
                    let socialKeywords = ["party","dinner","lunch","drinks","meet","coffee","birthday","wedding","date","hang","bar","restaurant","concert"]
                    let lowerTitle = ev.title.lowercased()
                    let keywordMatch = socialKeywords.contains { lowerTitle.contains($0) }
                    let duration = ev.endDate.timeIntervalSince(ev.startDate)
                    let isLong = duration > (60*60)
                    result = keywordMatch || isLong
                }

                events[idx].isSocial = result
                objectWillChange.send()
            } catch {
                classifyLocally()
                return
            }
        }
#else
        classifyLocally()
#endif
    }
}

struct CalendarClassifierView: View {
    @StateObject private var vm = CalendarClassifierViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if vm.events.isEmpty {
                    Text("No events loaded")
                        .foregroundStyle(.secondary)
                }
                List {
                    ForEach(vm.events) { e in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(e.title)
                                Text(e.startDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let isSocial = e.isSocial {
                                Text(isSocial ? "Social" : "Not social")
                                    .foregroundStyle(isSocial ? .green : .secondary)
                            }
                        }
                    }
                }
                HStack {
                    Button("Load & Request Access") { Task { await vm.requestAccessAndLoad() } }
                    Button("Classify (heuristic)") { vm.classifyLocally() }
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Model prompt example:")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Classify the following calendar event as social or not social. Provide probability and a one-sentence rationale. Event title: <title>. Start: <start>. End: <end>.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Calendar Classifier")
        }
    }
}

#Preview {
    CalendarClassifierView()
}

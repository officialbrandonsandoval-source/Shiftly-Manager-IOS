import Foundation

struct Escalation: Identifiable, Codable {
    let id: String
    let customerPhone: String
    let vehicleInterest: String?
    let qualificationScore: Int
    let escalationReason: String
    let escalatedAt: String
    let assignedTo: String?
    let status: String // pending, claimed, resolved

    enum CodingKeys: String, CodingKey {
        case id = "conversation_id"
        case customerPhone = "customer_phone"
        case vehicleInterest = "vehicle_interest"
        case qualificationScore = "qualification_score"
        case escalationReason = "escalation_reason"
        case escalatedAt = "escalated_at"
        case assignedTo = "assigned_to"
        case status
    }

    var timeSinceEscalation: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: escalatedAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: escalatedAt)
        }() else { return "" }

        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }

    var isPending: Bool { status.lowercased() == "pending" }
    var isClaimed: Bool { status.lowercased() == "claimed" }
    var isResolved: Bool { status.lowercased() == "resolved" }
}

struct EscalationStats: Codable {
    let activeCount: Int
    let avgResolveTimeMin: Double
    let escalationRateToday: Double

    enum CodingKeys: String, CodingKey {
        case activeCount = "active_count"
        case avgResolveTimeMin = "avg_resolve_time_min"
        case escalationRateToday = "escalation_rate_today"
    }
}

struct EscalationResponse: Codable {
    let escalations: [Escalation]
    let stats: EscalationStats
}

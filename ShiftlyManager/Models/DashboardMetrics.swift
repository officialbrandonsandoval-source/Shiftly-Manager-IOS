import Foundation

struct DashboardMetrics: Codable {
    let totalConversations: Int
    let activeConversations: Int
    let averageQualificationScore: Double
    let conversations: [ConversationSummary]

    enum CodingKeys: String, CodingKey {
        case totalConversations = "total_conversations"
        case activeConversations = "active_conversations"
        case averageQualificationScore = "average_qualification_score"
        case conversations
    }
}

struct ConversationSummary: Codable, Identifiable {
    let id: String
    let phone: String
    let customerName: String?
    let status: String
    let qualificationScore: Double?
    let lastMessageAt: String?
    let messageCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case customerName = "customer_name"
        case status
        case qualificationScore = "qualification_score"
        case lastMessageAt = "last_message_at"
        case messageCount = "message_count"
    }

    var displayName: String {
        customerName ?? phone
    }

    var formattedScore: String {
        guard let score = qualificationScore else { return "N/A" }
        return String(format: "%.0f%%", score * 100)
    }

    var statusColor: String {
        switch status.lowercased() {
        case "active": return "green"
        case "completed": return "blue"
        case "abandoned": return "gray"
        default: return "orange"
        }
    }
}

import Foundation

struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String?
    let role: String
    let content: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case createdAt = "created_at"
    }

    var isCustomer: Bool {
        role.lowercased() == "customer" || role.lowercased() == "user"
    }

    var isAgent: Bool {
        role.lowercased() == "agent" || role.lowercased() == "assistant"
    }

    var formattedTime: String {
        guard let dateString = createdAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else { return "" }
            return formatDate(date)
        }
        return formatDate(date)
    }

    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .none
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

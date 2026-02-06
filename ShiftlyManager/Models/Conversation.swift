import Foundation

struct Conversation: Codable, Identifiable {
    let id: String
    let phone: String
    let dealershipId: String
    let status: String
    let customerName: String?
    let qualificationScore: Double?
    let createdAt: String?
    let updatedAt: String?
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case dealershipId = "dealership_id"
        case status
        case customerName = "customer_name"
        case qualificationScore = "qualification_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case messages
    }

    var displayName: String {
        customerName ?? phone
    }
}

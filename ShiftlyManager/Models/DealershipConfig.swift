import Foundation

struct DealershipConfig: Codable {
    let dealershipName: String?
    let phone: String?
    let timezone: String?
    let smsProvider: String?
    let qualificationThreshold: Int?
    let modelTemperature: Double?
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case dealershipName = "dealership_name"
        case phone
        case timezone
        case smsProvider = "sms_provider"
        case qualificationThreshold = "qualification_threshold"
        case modelTemperature = "model_temperature"
        case maxTokens = "max_tokens"
    }
}

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .noData:
            return "No data received"
        }
    }
}

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "https://ai-agent-backend.onrender.com/api"
    private let apiKey = "dev-key-12345"
    private let dealershipId = "00000000-0000-0000-0000-000000000001"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        var components = URLComponents(string: baseURL + path)
        var items = queryItems
        items.append(URLQueryItem(name: "dealership_id", value: dealershipId))
        components?.queryItems = items

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    // MARK: - Dashboard

    func fetchDashboard() async throws -> DashboardMetrics {
        guard let request = makeRequest(path: "/admin/dashboard") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(DashboardMetrics.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Conversation Detail

    func fetchConversation(phone: String) async throws -> Conversation {
        let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? phone
        guard let request = makeRequest(path: "/agent/conversation/\(encodedPhone)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Conversation.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Escalations

    func fetchEscalations() async throws -> EscalationResponse {
        guard let request = makeRequest(path: "/admin/escalations") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        do {
            return try JSONDecoder().decode(EscalationResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func claimEscalation(_ id: String) async throws {
        guard var request = makeRequest(path: "/admin/escalations/\(id)/claim") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func resolveEscalation(_ id: String) async throws {
        guard var request = makeRequest(path: "/admin/escalations/\(id)/resolve") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // MARK: - Conversation Actions

    func sendManagerMessage(conversationId: String, message: String) async throws {
        guard var request = makeRequest(path: "/agent/handle-message") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "conversation_id": conversationId,
            "message": message,
            "source": "manager",
            "bypass_ai": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func escalateConversation(_ conversationId: String, reason: String) async throws {
        guard var request = makeRequest(path: "/agent/escalate") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "conversation_id": conversationId,
            "reason": reason,
            "priority": "high"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func updateConversationStatus(_ conversationId: String, status: String) async throws {
        guard var request = makeRequest(path: "/admin/conversations/\(conversationId)/status") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["status": status])

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // MARK: - Settings / Config

    func fetchDealershipConfig() async throws -> DealershipConfig {
        guard let request = makeRequest(path: "/admin/config") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        do {
            return try JSONDecoder().decode(DealershipConfig.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func updateDealershipConfig(qualificationThreshold: Int, temperature: Double, maxTokens: Int) async throws {
        guard var request = makeRequest(path: "/admin/config") else {
            throw APIError.invalidURL
        }
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "qualification_threshold": qualificationThreshold,
            "model_temperature": temperature,
            "max_tokens": maxTokens
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // MARK: - Health Check

    func checkHealth() async -> Bool {
        guard let request = makeRequest(path: "/health") else { return false }
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }
}

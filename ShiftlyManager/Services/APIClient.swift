import Foundation
import Combine

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
}

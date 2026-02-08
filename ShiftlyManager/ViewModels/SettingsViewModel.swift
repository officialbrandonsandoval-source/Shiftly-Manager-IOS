import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    // Dealership info (read-only)
    @Published var dealershipName = "—"
    @Published var phone = "—"
    @Published var timezone = "—"
    @Published var smsProvider = "—"

    // Agent config
    @Published var qualThresholdDouble: Double = 70
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 200

    // Notifications
    @Published var escalationAlerts = true
    @Published var highScoreAlerts = true
    @Published var alertThresholdDouble: Double = 70

    // Status
    @Published var apiHealthy = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSaveSuccess = false

    var qualThreshold: Int { Int(qualThresholdDouble) }
    var alertThreshold: Int { Int(alertThresholdDouble) }

    func loadConfig() async {
        isLoading = true
        do {
            let config = try await APIClient.shared.fetchDealershipConfig()
            dealershipName = config.dealershipName ?? "—"
            phone = config.phone ?? "—"
            timezone = config.timezone ?? "—"
            smsProvider = config.smsProvider ?? "—"
            qualThresholdDouble = Double(config.qualificationThreshold ?? 70)
            temperature = config.modelTemperature ?? 0.7
            maxTokens = config.maxTokens ?? 200
        } catch {
            // Silently fail for config, use defaults
            print("Failed to load config: \(error)")
        }

        // Check API health
        apiHealthy = await APIClient.shared.checkHealth()
        isLoading = false
    }

    func saveConfig() async {
        do {
            try await APIClient.shared.updateDealershipConfig(
                qualificationThreshold: qualThreshold,
                temperature: temperature,
                maxTokens: maxTokens
            )
            HapticManager.success()
            showSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

import Foundation

@MainActor
final class EscalationsViewModel: ObservableObject {
    @Published var escalations: [Escalation] = []
    @Published var stats: EscalationStats?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private var refreshTimer: Timer?

    var activeCount: Int {
        stats?.activeCount ?? escalations.filter { !$0.isResolved }.count
    }

    func loadEscalations() async {
        isLoading = escalations.isEmpty
        do {
            let response = try await APIClient.shared.fetchEscalations()
            escalations = response.escalations
            stats = response.stats

            // Check for new escalations and trigger local notifications
            for escalation in response.escalations where escalation.isPending {
                NotificationManager.shared.scheduleLocalEscalationAlert(
                    phone: escalation.customerPhone,
                    reason: escalation.escalationReason
                )
            }
            HapticManager.light()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func claimEscalation(_ id: String) async {
        do {
            try await APIClient.shared.claimEscalation(id)
            await loadEscalations()
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func resolveEscalation(_ id: String) async {
        do {
            try await APIClient.shared.resolveEscalation(id)
            await loadEscalations()
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadEscalations()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

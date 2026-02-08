import Foundation

@MainActor
final class LeadsViewModel: ObservableObject {
    @Published var leads: [ConversationSummary] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    enum LeadFilter: String, CaseIterable {
        case hot = "Hot (70+)"
        case warm = "Warm (40-69)"
        case all = "All"
    }

    func loadLeads() async {
        isLoading = leads.isEmpty
        do {
            let metrics = try await APIClient.shared.fetchDashboard()
            // Sort by qualification score descending
            leads = metrics.conversations
                .filter { $0.qualificationScore != nil }
                .sorted { ($0.qualificationScore ?? 0) > ($1.qualificationScore ?? 0) }
            HapticManager.light()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func filteredLeads(for filter: LeadFilter) -> [ConversationSummary] {
        switch filter {
        case .hot:
            return leads.filter { ($0.qualificationScore ?? 0) >= 0.7 }
        case .warm:
            return leads.filter {
                let score = $0.qualificationScore ?? 0
                return score >= 0.4 && score < 0.7
            }
        case .all:
            return leads
        }
    }

    func rank(for lead: ConversationSummary) -> Int {
        guard let index = leads.firstIndex(where: { $0.id == lead.id }) else { return 0 }
        return index + 1
    }
}

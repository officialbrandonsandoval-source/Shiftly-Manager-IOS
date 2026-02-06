import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading dashboard...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let metrics = viewModel.metrics {
                    VStack(spacing: 16) {
                        // KPI Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            KPICard(
                                title: "Total Conversations",
                                value: "\(metrics.totalConversations)",
                                icon: "message.fill",
                                color: .blue
                            )
                            KPICard(
                                title: "Active Now",
                                value: "\(metrics.activeConversations)",
                                icon: "bolt.fill",
                                color: .green
                            )
                            KPICard(
                                title: "Avg Score",
                                value: String(format: "%.0f%%", metrics.averageQualificationScore * 100),
                                icon: "chart.bar.fill",
                                color: .orange
                            )
                            KPICard(
                                title: "Completion",
                                value: completionRate(metrics),
                                icon: "checkmark.circle.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)

                        // Score Chart
                        if !metrics.conversations.isEmpty {
                            ScoreChartView(conversations: metrics.conversations)
                                .padding(.horizontal)
                        }

                        // Recent Conversations
                        if !metrics.conversations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Conversations")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(metrics.conversations.prefix(5)) { conversation in
                                    NavigationLink(destination: ConversationDetailView(phone: conversation.phone, name: conversation.displayName)) {
                                        RecentConversationRow(conversation: conversation)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Pull to refresh or check your connection.")
                    )
                }
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .navigationTitle("Shiftly Manager")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    Task { await viewModel.loadDashboard() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    private func completionRate(_ metrics: DashboardMetrics) -> String {
        guard metrics.totalConversations > 0 else { return "0%" }
        let completed = metrics.conversations.filter { $0.status.lowercased() == "completed" }.count
        let rate = Double(completed) / Double(metrics.totalConversations) * 100
        return String(format: "%.0f%%", rate)
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Score Chart

struct ScoreChartView: View {
    let conversations: [ConversationSummary]

    private var scoredConversations: [ConversationSummary] {
        conversations.filter { $0.qualificationScore != nil }.prefix(10).reversed().map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Qualification Scores")
                .font(.headline)

            if scoredConversations.isEmpty {
                Text("No scored conversations yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(scoredConversations) { conversation in
                        VStack(spacing: 4) {
                            Text(conversation.formattedScore)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: conversation.qualificationScore ?? 0))
                                .frame(height: barHeight(for: conversation.qualificationScore ?? 0))

                            Text(String(conversation.displayName.prefix(3)))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func barHeight(for score: Double) -> CGFloat {
        max(8, CGFloat(score) * 100)
    }

    private func barColor(for score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }
}

// MARK: - Recent Conversation Row

struct RecentConversationRow: View {
    let conversation: ConversationSummary

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(conversation.status.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let score = conversation.qualificationScore {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(scoreColor(score))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var statusColor: Color {
        switch conversation.status.lowercased() {
        case "active": return .green
        case "completed": return .blue
        case "abandoned": return .gray
        default: return .orange
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }
}

// MARK: - ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var metrics: DashboardMetrics?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    func loadDashboard() async {
        isLoading = true
        do {
            metrics = try await APIClient.shared.fetchDashboard()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    DashboardView()
}

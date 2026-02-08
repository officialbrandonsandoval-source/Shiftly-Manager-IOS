import SwiftUI

struct EscalationsView: View {
    @StateObject private var viewModel = EscalationsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                if let stats = viewModel.stats {
                    EscalationStatsBar(stats: stats)
                }

                // Content
                Group {
                    if viewModel.isLoading && viewModel.escalations.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading escalations...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.escalations.isEmpty {
                        ContentUnavailableView(
                            "No Escalations",
                            systemImage: "checkmark.shield.fill",
                            description: Text("All conversations are running smoothly.")
                        )
                    } else {
                        List {
                            ForEach(viewModel.escalations) { escalation in
                                EscalationRow(escalation: escalation)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if escalation.isPending {
                                            Button {
                                                Task { await viewModel.claimEscalation(escalation.id) }
                                            } label: {
                                                Label("Claim", systemImage: "hand.raised.fill")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if !escalation.isResolved {
                                            Button {
                                                Task { await viewModel.resolveEscalation(escalation.id) }
                                            } label: {
                                                Label("Resolve", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Escalations")
            .refreshable {
                await viewModel.loadEscalations()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    Task { await viewModel.loadEscalations() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadEscalations()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }
}

// MARK: - Stats Bar

struct EscalationStatsBar: View {
    let stats: EscalationStats

    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                label: "Active",
                value: "\(stats.activeCount)",
                color: .red
            )
            Divider().frame(height: 32)
            StatItem(
                label: "Avg Resolve",
                value: String(format: "%.0fm", stats.avgResolveTimeMin),
                color: .blue
            )
            Divider().frame(height: 32)
            StatItem(
                label: "Today's Rate",
                value: String(format: "%.0f%%", stats.escalationRateToday * 100),
                color: .orange
            )
        }
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Escalation Row

struct EscalationRow: View {
    let escalation: Escalation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)

                Text(escalation.customerPhone)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(escalation.timeSinceEscalation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let vehicle = escalation.vehicleInterest {
                Text(vehicle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(escalation.escalationReason)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)

                Spacer()

                // Status badge
                Text(escalation.status.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())

                // Score
                Text("Score: \(escalation.qualificationScore)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let assignee = escalation.assignedTo {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text(assignee)
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch escalation.status.lowercased() {
        case "pending": return .red
        case "claimed": return .orange
        case "resolved": return .green
        default: return .gray
        }
    }
}

#Preview {
    EscalationsView()
}

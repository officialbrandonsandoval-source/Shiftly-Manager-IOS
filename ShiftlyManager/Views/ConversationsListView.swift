import SwiftUI

struct ConversationsListView: View {
    @StateObject private var viewModel = ConversationsListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Pull to refresh to load conversations.")
                    )
                } else {
                    List(filteredConversations) { conversation in
                        NavigationLink(destination: ConversationDetailView(phone: conversation.phone, name: conversation.displayName)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $viewModel.searchText, prompt: "Search conversations")
                }
            }
            .refreshable {
                await viewModel.loadConversations()
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.filterStatus = nil
                        } label: {
                            Label("All", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                        }
                        Button {
                            viewModel.filterStatus = "active"
                        } label: {
                            Label("Active", systemImage: viewModel.filterStatus == "active" ? "checkmark" : "")
                        }
                        Button {
                            viewModel.filterStatus = "completed"
                        } label: {
                            Label("Completed", systemImage: viewModel.filterStatus == "completed" ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    Task { await viewModel.loadConversations() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadConversations()
            }
        }
    }

    private var filteredConversations: [ConversationSummary] {
        var result = viewModel.conversations

        if let status = viewModel.filterStatus {
            result = result.filter { $0.status.lowercased() == status }
        }

        if !viewModel.searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(viewModel.searchText) ||
                $0.phone.contains(viewModel.searchText)
            }
        }

        return result
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: ConversationSummary

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)
                Text(initials)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if let time = conversation.lastMessageAt {
                        Text(formatRelativeTime(time))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    StatusBadge(status: conversation.status)

                    Spacer()

                    if let count = conversation.messageCount {
                        Label("\(count)", systemImage: "message")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let score = conversation.qualificationScore {
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(scoreColor(score))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let name = conversation.displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal]
        let hash = abs(conversation.phone.hashValue)
        return colors[hash % colors.count]
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }

    private func formatRelativeTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else { return "" }
            return relativeString(from: date)
        }
        return relativeString(from: date)
    }

    private func relativeString(from date: Date) -> String {
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var textColor: Color {
        switch status.lowercased() {
        case "active": return .green
        case "completed": return .blue
        case "abandoned": return .gray
        default: return .orange
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.12)
    }
}

// MARK: - ViewModel

@MainActor
final class ConversationsListViewModel: ObservableObject {
    @Published var conversations: [ConversationSummary] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = ""
    @Published var filterStatus: String?

    func loadConversations() async {
        isLoading = true
        do {
            let metrics = try await APIClient.shared.fetchDashboard()
            conversations = metrics.conversations
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    ConversationsListView()
}

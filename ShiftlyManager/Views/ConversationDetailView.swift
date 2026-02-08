import SwiftUI

struct ConversationDetailView: View {
    let phone: String
    let name: String

    @StateObject private var viewModel = ConversationDetailViewModel()
    @State private var replyText = ""
    @State private var showEscalateAlert = false
    @State private var showCompleteAlert = false
    @State private var escalationReason = ""

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.conversation == nil {
                Spacer()
                ProgressView("Loading conversation...")
                Spacer()
            } else if let conversation = viewModel.conversation {
                // Customer Context Card
                CustomerContextCard(conversation: conversation)

                Divider()

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversation.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.conversation?.messages.count) { _, _ in
                        if let lastMessage = conversation.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Quick Reply Bar
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $replyText)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        sendReply()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(replyText.isEmpty || viewModel.isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            } else {
                ContentUnavailableView(
                    "Conversation Not Found",
                    systemImage: "message.badge.circle",
                    description: Text("Could not load this conversation.")
                )
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Call button
                Button {
                    callCustomer()
                } label: {
                    Image(systemName: "phone.fill")
                }

                // Escalate button
                Button {
                    showEscalateAlert = true
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                }

                // Complete button
                Button {
                    showCompleteAlert = true
                } label: {
                    Image(systemName: "checkmark.circle")
                }

                // Refresh button
                Button {
                    Task { await viewModel.loadConversation(phone: phone) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Escalate Conversation", isPresented: $showEscalateAlert) {
            TextField("Reason for escalation", text: $escalationReason)
            Button("Escalate", role: .destructive) {
                Task { await escalateConversation() }
            }
            Button("Cancel", role: .cancel) {
                escalationReason = ""
            }
        } message: {
            Text("This will flag the conversation for immediate attention.")
        }
        .alert("Complete Conversation", isPresented: $showCompleteAlert) {
            Button("Complete", role: .destructive) {
                Task { await completeConversation() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark this conversation as completed?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Retry") {
                Task { await viewModel.loadConversation(phone: phone) }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadConversation(phone: phone)
        }
        .onAppear {
            viewModel.startLiveRefreshIfActive(phone: phone)
        }
        .onDisappear {
            viewModel.stopLiveRefresh()
        }
    }

    private func sendReply() {
        let message = replyText
        replyText = ""
        Task {
            await viewModel.sendMessage(message: message, phone: phone)
        }
    }

    private func callCustomer() {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func escalateConversation() async {
        guard let conversation = viewModel.conversation else { return }
        let reason = escalationReason.isEmpty ? "Manager escalation" : escalationReason
        do {
            try await APIClient.shared.escalateConversation(conversation.id, reason: reason)
            HapticManager.warning()
            escalationReason = ""
            await viewModel.loadConversation(phone: phone)
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }

    private func completeConversation() async {
        guard let conversation = viewModel.conversation else { return }
        do {
            try await APIClient.shared.updateConversationStatus(conversation.id, status: "completed")
            HapticManager.success()
            await viewModel.loadConversation(phone: phone)
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}

// MARK: - Customer Context Card

struct CustomerContextCard: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        StatusBadge(status: conversation.status)
                        if let score = conversation.qualificationScore {
                            ScoreBar(score: score)
                        }
                    }
                    Text(conversation.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(conversation.messages.count) messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let updated = conversation.updatedAt {
                        Text(formatRelativeTime(updated))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Qualification score progress bar
            if let score = conversation.qualificationScore {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Qualification")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(scoreColor(score))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2))
                            Capsule().fill(scoreColor(score))
                                .frame(width: geo.size.width * score)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }

    private func formatRelativeTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }() else { return "" }

        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    private var isManager: Bool {
        message.role.lowercased() == "manager"
    }

    var body: some View {
        HStack {
            if !message.isCustomer {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.isCustomer ? .leading : .trailing, spacing: 4) {
                // Role label
                HStack(spacing: 4) {
                    Image(systemName: roleIcon)
                        .font(.caption2)
                    Text(roleLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(roleColor)

                // Bubble
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleColor)
                    .foregroundStyle(message.isCustomer ? .primary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Timestamp
                if !message.formattedTime.isEmpty {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if message.isCustomer {
                Spacer(minLength: 48)
            }
        }
    }

    private var roleIcon: String {
        if message.isCustomer { return "person.fill" }
        if isManager { return "person.badge.shield.checkmark" }
        return "cpu"
    }

    private var roleLabel: String {
        if message.isCustomer { return "Customer" }
        if isManager { return "Manager" }
        return "Agent"
    }

    private var roleColor: Color {
        if message.isCustomer { return .blue }
        if isManager { return .purple }
        return .green
    }

    private var bubbleColor: Color {
        if message.isCustomer { return Color(.systemGray5) }
        if isManager { return .purple }
        return .blue
    }
}

// MARK: - ViewModel

@MainActor
final class ConversationDetailViewModel: ObservableObject {
    @Published var conversation: Conversation?
    @Published var isLoading = false
    @Published var isSending = false
    @Published var showError = false
    @Published var errorMessage = ""

    private var refreshTimer: Timer?

    func loadConversation(phone: String) async {
        isLoading = conversation == nil
        do {
            conversation = try await APIClient.shared.fetchConversation(phone: phone)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func sendMessage(message: String, phone: String) async {
        guard let conversation else { return }
        isSending = true
        do {
            try await APIClient.shared.sendManagerMessage(
                conversationId: conversation.id,
                message: message
            )
            HapticManager.success()
            // Reload to show the new message
            await loadConversation(phone: phone)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSending = false
    }

    func startLiveRefreshIfActive(phone: String) {
        guard conversation?.status.lowercased() == "active" || conversation == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadConversation(phone: phone)
            }
        }
    }

    func stopLiveRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

#Preview {
    NavigationStack {
        ConversationDetailView(phone: "+15551234567", name: "John Doe")
    }
}

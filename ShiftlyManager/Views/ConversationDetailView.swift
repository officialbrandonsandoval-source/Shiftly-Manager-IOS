import SwiftUI

struct ConversationDetailView: View {
    let phone: String
    let name: String

    @StateObject private var viewModel = ConversationDetailViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading conversation...")
                Spacer()
            } else if let conversation = viewModel.conversation {
                // Conversation Info Header
                ConversationInfoHeader(conversation: conversation)

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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.loadConversation(phone: phone) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
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
    }
}

// MARK: - Conversation Info Header

struct ConversationInfoHeader: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    StatusBadge(status: conversation.status)
                    if let score = conversation.qualificationScore {
                        Text(String(format: "Score: %.0f%%", score * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if !message.isCustomer {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.isCustomer ? .leading : .trailing, spacing: 4) {
                // Role label
                HStack(spacing: 4) {
                    Image(systemName: message.isCustomer ? "person.fill" : "cpu")
                        .font(.caption2)
                    Text(message.isCustomer ? "Customer" : "Agent")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(message.isCustomer ? .blue : .green)

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

    private var bubbleColor: Color {
        message.isCustomer ? Color(.systemGray5) : .blue
    }
}

// MARK: - ViewModel

@MainActor
final class ConversationDetailViewModel: ObservableObject {
    @Published var conversation: Conversation?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    func loadConversation(phone: String) async {
        isLoading = true
        do {
            conversation = try await APIClient.shared.fetchConversation(phone: phone)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ConversationDetailView(phone: "+15551234567", name: "John Doe")
    }
}

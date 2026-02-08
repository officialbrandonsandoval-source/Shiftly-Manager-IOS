import SwiftUI

struct LeadRow: View {
    let lead: ConversationSummary
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank circle
            Text("#\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(scoreColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(lead.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let time = lead.lastMessageAt {
                    Text(formatRelativeTime(time))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Score bar
            if let score = lead.qualificationScore {
                ScoreBar(score: score)
            }
        }
        .padding(.vertical, 4)
    }

    private var scoreColor: Color {
        guard let score = lead.qualificationScore else { return .gray }
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

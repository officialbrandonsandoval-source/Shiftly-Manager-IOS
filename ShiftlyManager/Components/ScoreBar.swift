import SwiftUI

struct ScoreBar: View {
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    Capsule().fill(barColor).frame(width: geo.size.width * score)
                }
            }
            .frame(width: 60, height: 8)

            Text(String(format: "%.0f", score * 100))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(barColor)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var barColor: Color {
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }
}

#Preview {
    VStack(spacing: 12) {
        ScoreBar(score: 0.85)
        ScoreBar(score: 0.55)
        ScoreBar(score: 0.25)
    }
    .padding()
}

import SwiftUI

@main
struct ShiftlyManagerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }

                ConversationsListView()
                    .tabItem {
                        Label("Conversations", systemImage: "message.fill")
                    }
            }
            .tint(.blue)
        }
    }
}

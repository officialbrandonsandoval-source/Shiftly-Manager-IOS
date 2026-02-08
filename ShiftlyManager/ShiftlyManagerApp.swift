import SwiftUI

@main
struct ShiftlyManagerApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var escalationsViewModel = EscalationsViewModel()

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

                EscalationsView()
                    .tabItem {
                        Label("Escalations", systemImage: "exclamationmark.triangle.fill")
                    }
                    .badge(escalationsViewModel.activeCount)

                LeadsView()
                    .tabItem {
                        Label("Leads", systemImage: "star.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.blue)
            .task {
                await notificationManager.requestPermission()
                await escalationsViewModel.loadEscalations()
            }
        }
    }
}

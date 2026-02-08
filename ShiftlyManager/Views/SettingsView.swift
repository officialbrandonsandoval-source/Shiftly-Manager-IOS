import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Dealership") {
                    LabeledContent("Name", value: viewModel.dealershipName)
                    LabeledContent("Phone", value: viewModel.phone)
                    LabeledContent("Timezone", value: viewModel.timezone)
                    LabeledContent("SMS Provider", value: viewModel.smsProvider)
                }

                Section("Agent Configuration") {
                    VStack(alignment: .leading) {
                        Text("Qualification Threshold: \(viewModel.qualThreshold)")
                        Slider(value: $viewModel.qualThresholdDouble, in: 0...100, step: 5)
                    }
                    VStack(alignment: .leading) {
                        Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                        Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                    }
                    Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 100...500, step: 50)
                }

                Section("Notifications") {
                    Toggle("Escalation Alerts", isOn: $viewModel.escalationAlerts)
                    Toggle("High-Score Lead Alerts", isOn: $viewModel.highScoreAlerts)
                    if viewModel.highScoreAlerts {
                        VStack(alignment: .leading) {
                            Text("Alert Threshold: \(viewModel.alertThreshold)")
                            Slider(value: $viewModel.alertThresholdDouble, in: 0...100, step: 5)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    HStack {
                        Text("API Status")
                        Spacer()
                        Circle()
                            .fill(viewModel.apiHealthy ? .green : .red)
                            .frame(width: 10, height: 10)
                        Text(viewModel.apiHealthy ? "Connected" : "Disconnected")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Save Configuration") {
                        Task { await viewModel.saveConfig() }
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Settings")
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading settings...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Configuration saved successfully.")
            }
            .task {
                await viewModel.loadConfig()
            }
        }
    }
}

#Preview {
    SettingsView()
}

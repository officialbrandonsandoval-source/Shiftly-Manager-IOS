import SwiftUI

struct LeadsView: View {
    @StateObject private var viewModel = LeadsViewModel()
    @State private var selectedFilter: LeadsViewModel.LeadFilter = .hot

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(LeadsViewModel.LeadFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    if viewModel.isLoading && viewModel.leads.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading leads...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredLeads(for: selectedFilter).isEmpty {
                        ContentUnavailableView(
                            noLeadsTitle,
                            systemImage: "star.slash",
                            description: Text(noLeadsDescription)
                        )
                    } else {
                        List(viewModel.filteredLeads(for: selectedFilter)) { lead in
                            NavigationLink(destination: ConversationDetailView(phone: lead.phone, name: lead.displayName)) {
                                LeadRow(lead: lead, rank: viewModel.rank(for: lead))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Leads")
            .refreshable {
                await viewModel.loadLeads()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    Task { await viewModel.loadLeads() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadLeads()
            }
        }
    }

    private var noLeadsTitle: String {
        switch selectedFilter {
        case .hot: return "No Hot Leads"
        case .warm: return "No Warm Leads"
        case .all: return "No Leads"
        }
    }

    private var noLeadsDescription: String {
        switch selectedFilter {
        case .hot: return "No leads with a score of 70+ yet."
        case .warm: return "No leads with a score between 40-69."
        case .all: return "Pull to refresh to load leads."
        }
    }
}

#Preview {
    LeadsView()
}

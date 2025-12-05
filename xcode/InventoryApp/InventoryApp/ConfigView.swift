import SwiftUI

struct ConfigView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var pingMessage: String = ""

    var body: some View {
        Form {
            Section(header: Text("Backend")) {
                TextField("Base URL", text: $viewModel.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("API Key", text: $viewModel.apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Save and refresh") {
                    Task { await viewModel.refreshAll() }
                }
            }

            Section(header: Text("Quick actions")) {
                Button("Ping API") {
                    Task { await ping() }
                }
                if !pingMessage.isEmpty {
                    Text(pingMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Status")) {
                Text(viewModel.status)
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func pingURL() -> URL? {
        URL(string: "/docs", relativeTo: URL(string: viewModel.baseURL)?.appendingPathComponent(""))
    }

    private func ping() async {
        guard let url = pingURL() else {
            pingMessage = "Invalid URL"
            return
        }
        var request = URLRequest(url: url)
        if !viewModel.apiKey.isEmpty {
            request.setValue(viewModel.apiKey, forHTTPHeaderField: "x-api-key")
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                pingMessage = "Response \(http.statusCode)"
            } else {
                pingMessage = "Received response"
            }
        } catch {
            pingMessage = "Ping failed: \(error.localizedDescription)"
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConfigView()
                .environmentObject(AppViewModel())
        }
    }
}

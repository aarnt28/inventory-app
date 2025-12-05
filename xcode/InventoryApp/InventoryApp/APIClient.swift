import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .badStatus(let code):
            return "Request failed with status \(code)"
        }
    }
}

struct APIClient {
    private let baseURL: URL
    private let apiKey: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String, apiKey: String) {
        self.baseURL = URL(string: baseURL)?.appendingPathComponent("") ?? URL(string: "http://localhost:8000/")!
        self.apiKey = apiKey
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func fetchItems() async throws -> [InventoryItem] {
        let data = try await request(path: "/api/items/")
        return try decoder.decode([InventoryItem].self, from: data)
    }

    func fetchTransactions() async throws -> [InventoryTransaction] {
        let data = try await request(path: "/api/transactions/")
        return try decoder.decode([InventoryTransaction].self, from: data)
    }

    func createTransaction(_ payload: NewTransaction) async throws -> InventoryTransaction {
        let body = try encoder.encode(payload)
        let data = try await request(
            path: "/api/transactions/",
            method: "POST",
            body: body,
            contentType: "application/json"
        )
        return try decoder.decode(InventoryTransaction.self, from: data)
    }

    // MARK: - Private

    private func request(path: String, method: String = "GET", body: Data? = nil, contentType: String? = nil) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            return data
        }
        guard 200..<300 ~= http.statusCode else {
            throw APIClientError.badStatus(http.statusCode)
        }
        return data
    }
}

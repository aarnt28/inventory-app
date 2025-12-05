import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var transactions: [InventoryTransaction] = []
    @Published var status: String = "Ready"
    @Published var isLoading: Bool = false

    @AppStorage("apiBaseURL") var baseURL: String = "http://localhost:8000"
    @AppStorage("apiKey") var apiKey: String = ""

    private var client: APIClient {
        APIClient(baseURL: baseURL, apiKey: apiKey)
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadItems() }
            group.addTask { await self.loadTransactions() }
        }
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let latest = try await client.fetchItems()
            items = latest
            status = "Items synced"
        } catch {
            status = "Failed to load items: \(error.localizedDescription)"
        }
    }

    func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let latest = try await client.fetchTransactions()
            transactions = latest
            status = "Activity refreshed"
        } catch {
            status = "Failed to load activity: \(error.localizedDescription)"
        }
    }

    func logTransaction(barcode: String, amount: Double, type: String, unitCost: Double?, deviceId: String?, notes: String?) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let request = NewTransaction(
                barcode: barcode,
                amount: amount,
                type: type,
                unitCost: unitCost,
                deviceId: deviceId,
                vendorClient: nil,
                notes: notes
            )
            let created = try await client.createTransaction(request)
            transactions.insert(created, at: 0)
            status = "Logged \(type) for \(barcode)"
            // Update matching item quantity if present
            if let idx = items.firstIndex(where: { $0.barcode == barcode }) {
                var updated = items[idx]
                updated.quantity = (updated.quantity ?? 0) + Int(amount)
                items[idx] = updated
            } else {
                // Pull fresh items to stay aligned
                await loadItems()
            }
            return true
        } catch {
            status = "Failed to log: \(error.localizedDescription)"
            return false
        }
    }
}

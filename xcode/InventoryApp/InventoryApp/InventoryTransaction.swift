import Foundation

struct InventoryTransaction: Identifiable, Codable {
    let id: Int
    let itemID: Int
    let barcode: String
    let amount: Double
    let type: String
    let unitCost: Double?
    let deviceID: String?
    let vendorClient: String?
    let notes: String?
    let transSource: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case itemID = "item_id"
        case barcode
        case amount
        case type
        case unitCost = "unit_cost"
        case deviceID = "device_id"
        case vendorClient = "vendor_client"
        case notes
        case transSource = "trans_source"
        case timestamp
    }
}

struct NewTransaction: Codable {
    let barcode: String
    let amount: Double
    let type: String
    let unitCost: Double?
    let deviceId: String?
    let vendorClient: String?
    let notes: String?
    let transSource: String = "ios-app"

    enum CodingKeys: String, CodingKey {
        case barcode
        case amount
        case type
        case unitCost = "unit_cost"
        case deviceId = "device_id"
        case vendorClient = "vendor_client"
        case notes
        case transSource = "trans_source"
    }
}

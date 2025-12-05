import Foundation

struct InventoryItem: Identifiable, Codable {
    let id: Int
    let barcode: String
    let name: String
    let description: String?
    var quantity: Int?
    let sku: String?
    let imageURL: String?
    let imagePath: String?
    let previewURL: String?

    enum CodingKeys: String, CodingKey {
        case id, barcode, name, description, quantity, sku
        case imageURL = "image_url"
        case imagePath = "image_path"
        case previewURL = "preview_url"
    }
}

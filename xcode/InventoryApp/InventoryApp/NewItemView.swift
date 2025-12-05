import SwiftUI

struct NewItemView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var barcode: String = ""
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var quantity: String = ""
    @State private var sku: String = ""
    @State private var imageURL: String = ""
    @State private var autofilledFromExisting = false
    @State private var errorMessage: String = ""

    private var existingItem: InventoryItem? {
        viewModel.items.first(where: { $0.barcode == barcode })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Barcode")) {
                    TextField("Scan or type", text: $barcode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    TextField("Description", text: $description)
                    TextField("SKU (optional)", text: $sku)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Image URL (optional)", text: $imageURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Quantity")) {
                    TextField("Starting quantity", text: $quantity)
                        .keyboardType(.numberPad)
                }

                if let existingItem {
                    Section {
                        Label("Item already exists: \(existingItem.name)", systemImage: "checkmark.shield")
                            .foregroundStyle(.secondary)
                    }
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await submit() }
                    }
                    .disabled(barcode.trimmingCharacters(in: .whitespaces).isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: barcode) { newValue in
                handleBarcodeChange(newValue)
            }
        }
    }

    private func submit() async {
        errorMessage = ""
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedBarcode.isEmpty else {
            errorMessage = "Barcode and name are required"
            return
        }

        let qtyInt = Int(quantity)
        let success = await viewModel.createItem(
            barcode: trimmedBarcode,
            name: trimmedName,
            description: description.isEmpty ? nil : description,
            quantity: qtyInt,
            sku: sku.isEmpty ? nil : sku,
            imageURL: imageURL.isEmpty ? nil : imageURL
        )

        if success {
            await MainActor.run { dismiss() }
        } else {
            await MainActor.run {
                errorMessage = viewModel.status
            }
        }
    }

    private func handleBarcodeChange(_ newValue: String) {
        if let existingItem {
            name = existingItem.name
            autofilledFromExisting = true
        } else if autofilledFromExisting {
            name = ""
            autofilledFromExisting = false
        }
    }
}

struct NewItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewItemView()
                .environmentObject(AppViewModel())
        }
    }
}

import SwiftUI

struct ItemListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingNewItem = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.items.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No items yet")
                                .font(.headline)
                            Text("Add items from the web admin or API, then pull to refresh here.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    ForEach(viewModel.items) { item in
                        HStack(spacing: 12) {
                            AsyncImage(url: item.previewURL.flatMap(URL.init(string:))) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 64, height: 64)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipped()
                                        .cornerRadius(8)
                                case .failure:
                                    placeholder
                                @unknown default:
                                    placeholder
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Barcode: \(item.barcode)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let description = item.description, !description.isEmpty {
                                    Text(description)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let qty = item.quantity {
                                Text("Qty \(qty)")
                                    .font(.headline)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAll()
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await viewModel.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewItem) {
                NewItemView()
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
        .frame(width: 64, height: 64)
    }
}

struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        ItemListView()
            .environmentObject(AppViewModel())
    }
}

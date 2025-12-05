import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "shippingbox")
                }

            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }

            ConfigView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            await viewModel.refreshAll()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}

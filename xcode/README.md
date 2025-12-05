# Inventory iOS Companion (SwiftUI)

This folder contains a SwiftUI iOS app that talks to the FastAPI backend, supports API keys, and can scan barcodes to log transactions.

## Project layout
- `InventoryApp.xcodeproj` – open in Xcode 15+.
- `InventoryApp/` – SwiftUI sources, assets, and Info.plist (camera usage text included).
- `AppViewModel` – shared state + API calls.
- `BarcodeScannerView` – AVFoundation-based scanner wired to the transaction form.

## Running
1. Open `xcode/InventoryApp/InventoryApp.xcodeproj` in Xcode 15 or newer.
2. Set a signing team in *Signing & Capabilities* for the `InventoryApp` target.
3. Update the base URL and API key in Settings tab (defaults to `http://localhost:8000` and blank). Make sure the key matches `API_KEY` on the backend.
4. Run on a physical device for camera access; the simulator cannot scan live barcodes.

## Features
- View inventory items (uses `/api/items/`).
- Scan barcodes and post transactions to `/api/transactions/` with `x-api-key` header.
- Config screen to change base URL/API key and ping the backend.

## Notes
- App icon slots are defined but empty; drop your icons into `InventoryApp/Resources/Assets.xcassets/AppIcon.appiconset/`.
- Uses ISO8601 date decoding; backend should expose default FastAPI datetime strings.

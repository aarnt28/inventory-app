import SwiftUI
import AVFoundation

struct ScanView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var lastScannedCode: String = ""
    @State private var amount: Double = 1
    @State private var type: String = "add"
    @State private var unitCost: String = ""
    @State private var deviceId: String = ""
    @State private var notes: String = ""
    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scannerSection
                formSection
                statusSection
            }
            .padding()
        }
        .navigationTitle("Scan")
        .onAppear {
            requestCameraIfNeeded()
        }
    }

    private var scannerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Barcode scanner")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await viewModel.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.bottom, 4)

            if cameraAuthorized {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.08))
                        .frame(height: 260)
                        .overlay(
                            BarcodeScannerView { code in
                                lastScannedCode = code
                            }
                        )
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundStyle(.blue.opacity(0.4))
                        .frame(height: 260)
                }
                Text("Last scanned: \(lastScannedCode.isEmpty ? "—" : lastScannedCode)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Camera permission needed")
                        .font(.headline)
                    Text("Enable camera access to scan barcodes.")
                        .foregroundStyle(.secondary)
                    Button("Request access") {
                        requestCameraIfNeeded(force: true)
                    }
                }
            }
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log transaction")
                .font(.headline)

            TextField("Barcode", text: $lastScannedCode)
                .textContentType(.oneTimeCode)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            HStack {
                TextField("Amount", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                Picker("Type", selection: $type) {
                    Text("Add").tag("add")
                    Text("Use").tag("use")
                    Text("Adjust").tag("adjust")
                }
                .pickerStyle(.segmented)
            }

            TextField("Unit cost (optional)", text: $unitCost)
                .keyboardType(.decimalPad)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            TextField("Device ID (optional)", text: $deviceId)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            Button {
                Task { await submit() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Text("Send to backend")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(lastScannedCode.isEmpty || viewModel.isLoading)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Text(viewModel.status)
                .foregroundStyle(.secondary)
            if let tx = viewModel.transactions.first {
                Text("Latest: \(tx.type) \(tx.amount) for \(tx.barcode)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func requestCameraIfNeeded(force: Bool = false) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined, _ where force:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraAuthorized = granted
                }
            }
        default:
            cameraAuthorized = false
        }
    }

    private func submit() async {
        guard !lastScannedCode.isEmpty else { return }
        let success = await viewModel.logTransaction(
            barcode: lastScannedCode,
            amount: amount,
            type: type,
            unitCost: Double(unitCost),
            deviceId: deviceId.isEmpty ? nil : deviceId,
            notes: notes.isEmpty ? nil : notes
        )
        if success {
            notes = ""
        }
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
            .environmentObject(AppViewModel())
    }
}

import AVFoundation
import AudioToolbox
import SwiftUI

struct BarcodeScannerView: UIViewRepresentable {
    var onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        view.session = context.coordinator.session
        context.coordinator.start()
        return view
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let session = AVCaptureSession()
        private var isProcessing = false
        private let onCodeScanned: (String) -> Void

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
            super.init()
        }

        func start() {
            configureSession()
            session.startRunning()
        }

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device)
            else { return }

            session.beginConfiguration()
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [
                    .ean8, .ean13, .qr, .code128, .code39, .code93, .upce, .pdf417
                ]
            }
            session.commitConfiguration()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !isProcessing else { return }
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue
            else { return }

            isProcessing = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned(code)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
            }
        }
    }
}

final class CameraPreview: UIView {
    var session: AVCaptureSession? {
        didSet { configure() }
    }

    private func configure() {
        guard let session else { return }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.layer.addSublayer(layer)
        layer.frame = bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.frame = bounds }
    }
}

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {

    enum ScanError: Error {
        case badInput
        case badOutput
    }

    let completion: (Result<String, ScanError>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .black

        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            completion(.failure(.badInput))
            return controller
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill

        // 🔑 IMPORTANT: use controller.view.bounds
        previewLayer.frame = controller.view.bounds
        controller.view.layer.addSublayer(previewLayer)

        // 🔹 Overlay (CENTERED)
        let overlay = ScannerOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = .clear
        controller.view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: controller.view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])

        session.startRunning()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let completion: (Result<String, ScanError>) -> Void

        init(completion: @escaping (Result<String, ScanError>) -> Void) {
            self.completion = completion
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let code = object.stringValue
            else { return }

            completion(.success(code))
        }
    }
}

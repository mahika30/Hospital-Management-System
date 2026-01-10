import SwiftUI
import AVFoundation

struct ScanPatientView: View {

    @State private var scannedPatientId: UUID?
    @State private var navigateToProfile = false

    var body: some View {
        ZStack {
            QRScannerView { result in
                switch result {
                case .success(let code):
                    // ✅ Convert QR string → UUID safely
                    if let uuid = UUID(uuidString: code) {
                        scannedPatientId = uuid
                        navigateToProfile = true
                    } else {
                        print("❌ Invalid patient QR code")
                    }

                case .failure(let error):
                    print("QR Scan error:", error)
                }
            }

            VStack {
                Spacer()
                Text("Scan Patient QR Code")
                    .font(.headline)
                    .padding(.bottom, 40)
                    .foregroundColor(.white)
            }
        }
        .navigationTitle("Scan Patient")
        .navigationDestination(isPresented: $navigateToProfile) {
            if let patientId = scannedPatientId {
                PatientDetailLoaderView(patientId: patientId)
            }
        }
    }
}

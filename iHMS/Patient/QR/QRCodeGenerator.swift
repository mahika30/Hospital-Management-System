import UIKit
import CoreImage.CIFilterBuiltins

final class QRCodeGenerator {

    static func generate(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "Q"

        if let outputImage = filter.outputImage {
            let scaled = outputImage.transformed(
                by: CGAffineTransform(scaleX: 10, y: 10)
            )
            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage()
    }
}

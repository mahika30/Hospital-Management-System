import UIKit

import UIKit

final class ScannerOverlayView: UIView {

    private let scanSize: CGFloat = 260

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
        ctx.fill(rect)

        let scanRect = CGRect(
            x: (rect.width - scanSize) / 2,
            y: (rect.height - scanSize) / 2,
            width: scanSize,
            height: scanSize
        )

        ctx.clear(scanRect)
        let borderPath = UIBezierPath(
            roundedRect: scanRect,
            cornerRadius: 22
        )

        UIColor.white.withAlphaComponent(0.6).setStroke()
        borderPath.lineWidth = 1.2
        borderPath.stroke()

        ctx.setShadow(
            offset: .zero,
            blur: 10,
            color: UIColor.white.withAlphaComponent(0.25).cgColor
        )
        borderPath.stroke()
    }
}

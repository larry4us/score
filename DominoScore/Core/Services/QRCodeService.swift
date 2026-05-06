//
//  QRCodeService.swift
//  DominoScore
//

import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

/// Generates and scans QR codes for session sharing.
struct QRCodeService {

    /// Generates a QR code image from a session code string.
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

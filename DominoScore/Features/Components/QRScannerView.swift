//
//  QRScannerView.swift
//  DominoScore
//

import SwiftUI
import VisionKit
import Vision

/// Camera-based QR code scanner presented as a modal sheet.
/// Uses `DataScannerViewController` to detect QR codes and returns the payload.
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onCodeScanned: (String) -> Void

    @State private var scannedCode: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported {
                    DataScannerRepresentable { code in
                        guard scannedCode == nil else { return }
                        scannedCode = code
                        onCodeScanned(code)
                        dismiss()
                    }
                    .ignoresSafeArea()
                    
                } else {
                    ContentUnavailableView(
                        "Câmera indisponível",
                        systemImage: "camera.fill",
                        description: Text("Este dispositivo não suporta leitura de QR Code.")
                    )
                }
            }
            .navigationTitle("Escanear QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DataScanner UIViewControllerRepresentable

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if not already scanning
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        coordinator.scanTask?.cancel()
        uiViewController.stopScanning()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        private var hasScanned = false
        var scanTask: Task<Void, Never>?

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handleItem(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let first = addedItems.first else { return }
            handleItem(first)
        }

        private func handleItem(_ item: RecognizedItem) {
            guard !hasScanned else { return }
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue, !payload.isEmpty {
                    hasScanned = true
                    onCodeScanned(payload)
                }
            default:
                break
            }
        }
    }
}

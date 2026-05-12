//
//  QRCodeSheet.swift
//  DominoScore
//
//  Created by Pedro Larry Rodrigues Lopes on 12/05/26.
//
import SwiftUI

// MARK: - QR Code Sheet

struct QRCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    private let qrService = QRCodeService()
    
    var body: some View {
        
        VStack(spacing: 24) {
            Spacer()
            
            Text("Compartilhar Sala")
                .font(.title2.bold())
            
            Text("Peça para escanearem este código para entrar na sala")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let uiImage = qrService.generateQRCode(from: code) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(16)
                    .glassEffect(in: .rect(cornerRadius: 20))
            }
            
            Text(code)
                .font(.title3.monospaced().bold())
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fechar") { dismiss() }
            }
        }
    }
}

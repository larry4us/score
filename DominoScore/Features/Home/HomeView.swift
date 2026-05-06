//
//  HomeView.swift
//  DominoScore
//

import SwiftUI

/// Main hub: create a session, join by code, or scan QR.
struct HomeView: View {
    @State private var sessionCode = ""
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Button {
                    // TODO: Create new session
                } label: {
                    Label("Nova Partida", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                HStack {
                    TextField("Codigo da sala", text: $sessionCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)

                    Button("Entrar") {
                        // TODO: Join session by code
                    }
                    .buttonStyle(.bordered)
                    .disabled(sessionCode.count < 6)
                }

                Button {
                    showScanner = true
                } label: {
                    Label("Escanear QR Code", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()
            }
            .padding()
            .navigationTitle("DominoScore")
        }
    }
}

#Preview {
    HomeView()
}

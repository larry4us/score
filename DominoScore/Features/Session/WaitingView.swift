//
//  WaitingView.swift
//  DominoScore
//

import SwiftUI

/// Waiting room shown before the game starts.
struct WaitingView: View {
    let session: Session
    let participants: [Participant]
    let onAddPlayer: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 4) {
                Text("Código da Sala")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.code)
                    .font(.largeTitle.monospaced().bold())
                    .padding()
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            }

            if !participants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jogadores (\(participants.count))")
                        .font(.headline)
                    ForEach(participants) { p in
                        Label(p.name, systemImage: "person.fill")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Adicionar Jogador", systemImage: "person.badge.plus", action: onAddPlayer)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(participants.count >= 4)

                Button("Iniciar Partida", action: onStart)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(participants.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    WaitingView(
        session: .mock,
        participants: Session.mock.participants,
        onAddPlayer: {},
        onStart: {}
    )
}

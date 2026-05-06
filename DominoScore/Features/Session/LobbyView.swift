//
//  LobbyView.swift
//  DominoScore
//

import SwiftUI

/// Waiting room before the game starts. Shows session code and status in real-time.
struct LobbyView: View {
    @Environment(Coordinator.self) private var coordinator
    let session: Session

    private var repo: SessionRepository { coordinator.sessionRepository }

    /// Sessão em tempo real (fallback para a snapshot inicial).
    private var liveSession: Session { repo.currentSession ?? session }

    var body: some View {
        VStack(spacing: 24) {

            // Código da sala
            VStack(spacing: 4) {
                Text("Código da Sala")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(liveSession.code)
                    .font(.largeTitle.monospaced().bold())
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(statusLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Ações de status
            VStack(spacing: 12) {
                if liveSession.status == .waiting {
                    Button("Iniciar Partida") {
                        Task { await updateStatus(.active) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if liveSession.status == .active {
                    Button("Finalizar Partida") {
                        Task { await updateStatus(.finished) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if liveSession.status == .finished {
                    Text("Partida encerrada")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("Lobby")
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch liveSession.status {
        case .waiting:  .orange
        case .active:   .green
        case .finished: .gray
        }
    }

    private var statusLabel: String {
        switch liveSession.status {
        case .waiting:  "Aguardando jogadores"
        case .active:   "Partida em andamento"
        case .finished: "Finalizada"
        }
    }

    private func updateStatus(_ status: Session.Status) async {
        guard let id = liveSession.id else { return }
        await repo.updateStatus(status, sessionId: id)
    }
}

//
//  HomeView.swift
//  DominoScore
//

import SwiftUI

/// Main hub: create a session, join by code, or scan QR.
struct CreateSessionView: View {
    @Environment(Coordinator.self) private var coordinator
    @State private var sessionCode = ""
    @State private var isLoading = false
    @State private var hasNavigated = false
    @State private var activeSession: Session?

    private var repo: SessionRepository { coordinator.sessionRepository }
    private var hostUid: String { coordinator.authService?.currentUserId ?? "" }
    private var hostFirstName: String {
        let full = coordinator.authService?.displayName ?? ""
        return full.components(separatedBy: " ").first ?? full
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Criar nova sessão
            Button {
                Task { await createSession() }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Nova Partida", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading)

            // Entrar por código
            HStack {
                TextField("Codigo da sala", text: $sessionCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button("Entrar") {
                    Task { await findSession() }
                }
                .buttonStyle(.bordered)
                .disabled(sessionCode.count < 5 || isLoading)
            }

            // Erro
            if let error = repo.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("DominoScore")
        .onChange(of: repo.currentSession) { _, session in
            guard let session, !hasNavigated else { return }
            hasNavigated = true
            activeSession = session
        }
        .onAppear {
            hasNavigated = false
        }
        .fullScreenCover(item: $activeSession, onDismiss: {
            hasNavigated = false
            sessionCode = ""
        }) { session in
            NavigationStack {
                LobbyView(session: session)
                    .environment(coordinator)
            }
        }
    }

    // MARK: - Actions

    private func createSession() async {
        isLoading = true
        let hostParticipant = Participant(name: hostFirstName, ownerUid: hostUid)
        await repo.createSession(hostUid: hostUid, initialParticipant: hostParticipant)
        isLoading = false
    }

    private func findSession() async {
        isLoading = true
        await repo.findSession(byCode: sessionCode.trimmingCharacters(in: .whitespaces))
        isLoading = false
    }
}

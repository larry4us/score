//
//  CreateSessionView.swift
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
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var showScanner = false

    private var repo: SessionRepository { coordinator.sessionRepository }
    private var hostUid: String { coordinator.authService?.currentUserId ?? "" }
    private var hostFirstName: String {
        let full = coordinator.authService?.displayName ?? ""
        return full.components(separatedBy: " ").first ?? full
    }

    private var displayName: String {
        coordinator.authService?.displayName ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Greeting
            GreetingHeader(name: hostFirstName)

            Spacer()

            // Central action area
            VStack(spacing: 32) {
                CreateSessionButton(isLoading: isLoading) {
                    Task { await createSession() }
                }

                JoinSessionSection(
                    sessionCode: $sessionCode,
                    isLoading: isLoading,
                    onScan: { showScanner = true },
                    onJoin: { Task { await findSession() } }
                )
            }

            Spacer()

            // Error message
            if let error = repo.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
        }
        .padding()
        .navigationTitle("DominoScore")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileMenu(
                    displayName: displayName,
                    onEditName: {
                        editedName = displayName
                        showEditName = true
                    },
                    onSignOut: { coordinator.authService?.signOut() }
                )
            }
        }
        .alert("Editar Nome", isPresented: $showEditName) {
            TextField("Seu nome", text: $editedName)
            Button("Salvar") {
                let name = editedName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                Task {
                    try? await coordinator.authService?.updateDisplayName(name)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Digite seu novo nome")
        }
        .onChange(of: repo.currentSession) { _, session in
            guard let session, !hasNavigated else { return }
            hasNavigated = true
            activeSession = session
        }
        .onAppear {
            hasNavigated = false
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { code in
                sessionCode = code
                Task { await findSession() }
            }
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
        let hostParticipant = Participant(id: hostUid, name: hostFirstName, ownerUid: hostUid)
        await repo.createSession(hostUid: hostUid, initialParticipant: hostParticipant)
        isLoading = false
    }

    private func findSession() async {
        isLoading = true
        await repo.findSession(byCode: sessionCode.trimmingCharacters(in: .whitespaces))
        isLoading = false
    }
}

// MARK: - Greeting Header

private struct GreetingHeader: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Olá, \(name)!")
                .font(.title.bold())
            Text("Crie ou entre em uma partida")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Create Session Button

private struct CreateSessionButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    Label("Nova Partida", systemImage: "plus.circle.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(isLoading)
    }
}

// MARK: - Join Session Section

private struct JoinSessionSection: View {
    @Binding var sessionCode: String
    let isLoading: Bool
    let onScan: () -> Void
    let onJoin: () -> Void

    private var canJoin: Bool {
        sessionCode.count >= 5 && !isLoading
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Ou entre com um código")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                TextField("Código da sala", text: $sessionCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button("Escanear QR", systemImage: "qrcode.viewfinder", action: onScan)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
            }

            Button(action: onJoin) {
                Text("Entrar na Sala")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .disabled(!canJoin)
        }
    }
}

// MARK: - Profile Menu

private struct ProfileMenu: View {
    let displayName: String
    let onEditName: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        Menu("Perfil", systemImage: "person.crop.circle") {
            Button("Editar Nome", systemImage: "pencil", action: onEditName)

            Divider()

            Button(role: .destructive, action: onSignOut) {
                Label("Sair", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .labelStyle(.iconOnly)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateSessionView()
            .environment(Coordinator(authenticated: true))
    }
}

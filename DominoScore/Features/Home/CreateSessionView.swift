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
    @State private var showEditName = false
    @State private var editedName = ""

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
        VStack(spacing: 24) {
            // Greeting
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(hostFirstName)!")
                    .font(.title.bold())
                Text("Crie ou entre em uma partida")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

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
            .buttonStyle(.glassProminent)
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
                .buttonStyle(.glass)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        editedName = displayName
                        showEditName = true
                    } label: {
                        Label("Editar Nome", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        coordinator.authService?.signOut()
                    } label: {
                        Label("Sair", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                }
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
#Preview {
    NavigationStack {
        CreateSessionView()
            .environment(Coordinator(authenticated: true))
    }
}
